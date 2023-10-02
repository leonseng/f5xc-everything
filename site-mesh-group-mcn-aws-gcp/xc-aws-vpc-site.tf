
resource "aws_security_group" "ce_slo" {
  name        = "ce_slo"
  description = "Allow TLS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "allow any from VPC - TCP"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  ingress {
    description = "allow any from VPC - ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ce_slo"
  }
}

resource "aws_security_group" "ce_sli" {
  name        = "ce_sli"
  description = "Allow any"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "allow any"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ce_sli"
  }
}

resource "volterra_enhanced_firewall_policy" "aws" {
  name      = "${local.name_prefix}-aws"
  namespace = "system"

  rule_list {
    rules {
      allow            = true
      inside_sources   = true
      all_destinations = true

      applications {
        applications = ["APPLICATION_HTTP"]
      }

      advanced_action {
        action = "LOG"
      }

      metadata {
        name = "allow-http"
      }
    }

    rules {
      allow            = true
      inside_sources   = true
      all_destinations = true

      protocol_port_range {
        protocol    = "ALL"
        port_ranges = ["5201"]
      }

      advanced_action {
        action = "LOG"
      }

      metadata {
        name = "allow-iperf"
      }
    }

    rules {
      deny             = true
      all_sources      = true
      all_destinations = true
      all_traffic      = true

      advanced_action {
        action = "LOG"
      }

      metadata {
        name = "deny-all"
      }
    }
  }
}

resource "volterra_cloud_credentials" "aws" {
  name      = "${local.name_prefix}-aws-cc"
  namespace = "system"

  aws_secret_key {
    access_key = var.xc_aws_access_key
    secret_key {
      clear_secret_info {
        url = "string:///${base64encode(var.xc_aws_secret_key)}"
      }
    }
  }
}

resource "volterra_aws_vpc_site" "this" {
  depends_on = [volterra_cloud_credentials.aws]

  name                    = "${local.name_prefix}-aws"
  namespace               = "system"
  aws_region              = var.aws_region
  instance_type           = var.xc_aws_ce_instance_type
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
    no_outside_static_routes = true

    global_network_list {
      global_network_connections {
        sli_to_global_dr {
          global_vn {
            tenant    = var.xc_tenant_id
            namespace = "system"
            name      = volterra_virtual_network.global.name
          }
        }
      }
    }

    inside_static_routes {
      static_route_list {
        custom_static_route {
          subnets {
            ipv4 {
              prefix = split("/", local.aws_vm_cidr)[0]
              plen   = split("/", local.aws_vm_cidr)[1]
            }
          }
          nexthop {
            type = "NEXT_HOP_NETWORK_INTERFACE"
            interface {
              tenant    = var.xc_tenant_id
              namespace = "system"
              name      = volterra_network_interface.inside.name
            }
          }
          attrs = ["ROUTE_ATTR_INSTALL_FORWARDING"]
        }
      }
    }

    active_enhanced_firewall_policies {
      enhanced_firewall_policies {
        tenant    = var.xc_tenant_id
        namespace = "system"
        name      = volterra_enhanced_firewall_policy.aws.name
      }
    }

    allowed_vip_port {
      use_http_https_port = true
    }

    dynamic "az_nodes" {
      for_each = range(0, var.aws_az_count)
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

  custom_security_group {
    inside_security_group_id  = aws_security_group.ce_sli.id
    outside_security_group_id = aws_security_group.ce_slo.id
  }

  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "volterra_tf_params_action" "aws_site_provisioner" {
  depends_on = [
    volterra_aws_vpc_site.this
  ]
  site_name       = "${local.name_prefix}-aws"
  site_kind       = "aws_vpc_site"
  action          = "apply"
  wait_for_action = true
}

data "aws_network_interfaces" "ce_inside" {
  depends_on = [volterra_tf_params_action.aws_site_provisioner]
  filter {
    name   = "tag:ves-io-site-name"
    values = ["${local.name_prefix}-aws"]
  }

  filter {
    name   = "tag:ves-io-eni-type"
    values = ["inside-network"]
  }
}

data "aws_network_interface" "ce_inside" {
  count = var.aws_az_count

  id = data.aws_network_interfaces.ce_inside.ids[count.index]
}

locals {
  ce_inside_eni_by_az = { for eni in data.aws_network_interface.ce_inside : eni.availability_zone => eni.id }
}

resource "aws_route" "to_gcp_vm" {
  count = var.aws_az_count

  route_table_id         = aws_route_table.vm[count.index].id
  destination_cidr_block = google_compute_subnetwork.vm.ip_cidr_range
  network_interface_id   = local.ce_inside_eni_by_az[aws_subnet.vm[count.index].availability_zone]
}

resource "aws_route" "to_gcp_inside" {
  count = var.aws_az_count

  route_table_id         = aws_route_table.vm[count.index].id
  destination_cidr_block = google_compute_subnetwork.inside.ip_cidr_range
  network_interface_id   = local.ce_inside_eni_by_az[aws_subnet.vm[count.index].availability_zone]
}

