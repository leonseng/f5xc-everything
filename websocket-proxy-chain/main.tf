provider "aws" {
  region = var.region
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "random_id" "id" {
  byte_length = 4
  prefix      = var.project_prefix
}

locals {
  vpc_cidr = "10.0.0.0/16"
  my_ip    = chomp(data.http.myip.response_body)
}

data "aws_availability_zones" "this" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }

  filter {
    name   = "region-name"
    values = [var.region]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name                    = random_id.id.dec
  cidr                    = local.vpc_cidr
  azs                     = [data.aws_availability_zones.this.names[0]]
  public_subnets          = [cidrsubnet(local.vpc_cidr, 8, 1)]
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true
}
