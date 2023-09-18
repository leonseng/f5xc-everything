resource "volterra_aws_vpc_site" "this" {
  depends_on = [volterra_cloud_credentials.aws]

  name                    = "${local.name_prefix}-aws"
  namespace               = "system"
  aws_region              = var.aws_region
  instance_type           = "t3.xlarge"
  logs_streaming_disabled = true
  no_worker_nodes         = true
  ssh_key                 = var.ssh_public_key

  labels = {
    "deployment_id" = local.name_prefix
  }

  aws_cred {
    name      = volterra_cloud_credentials.aws.name
    namespace = "system"
    tenant    = var.xc_tenant_id
  }

  vpc {
    vpc_id = aws_vpc.main.id
  }

  ingress_egress_gw {
    aws_certified_hw         = "aws-byol-multi-nic-voltmesh"
    no_dc_cluster_group      = true
    no_forward_proxy         = true
    no_inside_static_routes  = true
    no_network_policy        = true
    no_outside_static_routes = true

    allowed_vip_port {
      use_http_https_port = true
    }

    dynamic "az_nodes" {
      for_each = range(0, var.az_count)
      content {
        aws_az_name = data.aws_availability_zones.available.names[az_nodes.key]
        disk_size   = 80

        outside_subnet {
          existing_subnet_id = aws_subnet.outside[az_nodes.key].id
        }

        inside_subnet {
          existing_subnet_id = aws_subnet.inside[az_nodes.key].id
        }

        workload_subnet {
          existing_subnet_id = aws_subnet.workload[az_nodes.key].id
        }
      }
    }
  }
}

# resource "volterra_tf_params_action" "aws_site_provisioner" {
#   depends_on = [
#     volterra_aws_vpc_site.this
#   ]
#   site_name       = "${local.name_prefix}-aws"
#   site_kind       = "aws_vpc_site"
#   action          = "apply"
#   wait_for_action = true
# }
