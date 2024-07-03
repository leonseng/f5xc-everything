terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~> 0.11"
    }

    restapi = {
      source  = "Mastercard/restapi"
      version = ">= 1.18.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_name}-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  name_prefix = random_id.id.dec
  my_ip       = chomp(data.http.myip.response_body)
}

module "aws_vpc" {
  source = "./modules/aws-vpc"

  aws_region         = var.aws_region
  aws_az_count       = var.aws_az_count
  object_name_prefix = local.name_prefix
}

provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.f5xc_api_url
}

provider "restapi" {
  uri                   = var.f5xc_api_url
  create_returns_object = true
  headers = {
    Authorization = format("APIToken %s", var.f5xc_api_token)
    Content-Type  = "application/json"
  }
}

module "aws_byo_ce" {
  # source     = "git::https://github.com/f5devcentral/f5-xc-tf-modules.git//f5xc/ce/aws?ref=1dc538e"
  source     = "git::https://github.com/f5devcentral/f5-xc-tf-modules.git//f5xc/ce/aws?ref=9e302a5"
  depends_on = [module.aws_vpc]
  count      = var.aws_az_count

  aws_region             = var.aws_region
  owner_tag              = var.owner_tag
  is_sensitive           = false
  has_public_ip          = false
  create_new_aws_vpc     = false
  create_new_aws_igw     = false
  create_new_aws_slo_rt  = false
  create_new_aws_slo_rta = false
  create_new_aws_sli_rt  = false
  create_new_aws_sli_rta = false
  f5xc_tenant            = var.f5xc_tenant
  f5xc_api_url           = var.f5xc_api_url
  f5xc_api_token         = var.f5xc_api_token
  f5xc_namespace         = "system"
  f5xc_token_name        = "${local.name_prefix}-${count.index}"
  f5xc_cluster_name      = "${local.name_prefix}-${count.index}"
  f5xc_cluster_labels    = {}
  f5xc_aws_vpc_az_nodes = {
    node0 = {
      aws_existing_slo_subnet_id = module.aws_vpc.node_subnets[count.index].outside_subnet
      aws_existing_sli_subnet_id = module.aws_vpc.node_subnets[count.index].inside_subnet
      aws_vpc_az_name            = module.aws_vpc.node_subnets[count.index].az
    }
  }
  f5xc_ce_machine_image                  = var.f5xc_ce_machine_image
  f5xc_ce_gateway_type                   = var.f5xc_ce_gateway_type
  f5xc_cluster_latitude                  = var.f5xc_cluster_latitude
  f5xc_cluster_longitude                 = var.f5xc_cluster_longitude
  aws_existing_vpc_id                    = module.aws_vpc.vpc_id
  aws_security_group_rules_slo_egress    = []
  aws_security_group_rules_slo_ingress   = []
  ssh_public_key                         = var.ssh_public_key
  f5xc_enable_offline_survivability_mode = true
  f5xc_ce_performance_enhancement_mode = {
    perf_mode_l7_enhanced = true
  }
}
