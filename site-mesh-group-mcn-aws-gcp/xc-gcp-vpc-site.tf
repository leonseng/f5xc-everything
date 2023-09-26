resource "volterra_cloud_credentials" "gcp" {
  name      = "${local.name_prefix}-gcp-cc"
  namespace = "system"

  gcp_cred_file {
    credential_file {
      clear_secret_info {
        url = "string:///${google_service_account_key.this.private_key}"
      }
    }
  }
}

resource "volterra_gcp_vpc_site" "this" {
  depends_on = [google_project_iam_binding.this, volterra_cloud_credentials.gcp]

  name                    = "${local.name_prefix}-gcp"
  namespace               = "system"
  gcp_region              = var.gcp_region
  instance_type           = "n1-standard-4"
  logs_streaming_disabled = true
  ssh_key                 = var.ssh_public_key

  labels = {
    "deployment_id" = local.name_prefix
  }

  cloud_credentials {
    name      = volterra_cloud_credentials.gcp.name
    namespace = "system"
    tenant    = var.xc_tenant_id
  }

  ingress_egress_gw {
    node_number              = var.gcp_zone_count
    gcp_certified_hw         = "gcp-byol-multi-nic-voltmesh"
    gcp_zone_names           = slice(data.google_compute_zones.available.names, 0, var.gcp_zone_count)
    no_dc_cluster_group      = true
    no_forward_proxy         = true
    no_network_policy        = true
    no_outside_static_routes = true
    sm_connection_public_ip  = true

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
              prefix = split("/", local.gcp_vm_cidr)[0]
              plen   = split("/", local.gcp_vm_cidr)[1]
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

    performance_enhancement_mode {
      perf_mode_l7_enhanced = true
    }

    inside_network {
      existing_network {
        name = google_compute_network.inside.name
      }
    }

    inside_subnet {
      existing_subnet {
        subnet_name = google_compute_subnetwork.inside.name
      }
    }

    outside_network {
      existing_network {
        name = google_compute_network.outside.name
      }
    }

    outside_subnet {
      existing_subnet {
        subnet_name = google_compute_subnetwork.outside.name
      }
    }
  }

  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "volterra_tf_params_action" "gcp_site_provisioner" {
  depends_on = [
    volterra_gcp_vpc_site.this
  ]
  site_name       = "${local.name_prefix}-gcp"
  site_kind       = "gcp_vpc_site"
  action          = "apply"
  wait_for_action = true
}

data "google_compute_region_instance_group" "ce" {
  depends_on = [volterra_tf_params_action.gcp_site_provisioner]
  name       = "${local.name_prefix}-gcp"
}

data "google_compute_instance" "ce" {
  count = var.gcp_zone_count

  self_link = data.google_compute_region_instance_group.ce.instances[count.index].instance
}

resource "google_compute_route" "vm_to_aws" {
  count = var.gcp_zone_count

  name        = "${local.name_prefix}-to-aws-${count.index + 1}"
  dest_range  = local.aws_vm_cidr
  network     = google_compute_network.inside.name
  next_hop_ip = data.google_compute_instance.ce[count.index].network_interface[1].network_ip
  priority    = 100
  tags        = ["${local.name_prefix}-vm-${count.index + 1}"]
}

resource "google_compute_route" "vm_to_aws_workload" {
  count = var.gcp_zone_count

  name        = "${local.name_prefix}-to-aws-workload-${count.index + 1}"
  dest_range  = local.aws_workload_cidr
  network     = google_compute_network.inside.name
  next_hop_ip = data.google_compute_instance.ce[count.index].network_interface[1].network_ip
  priority    = 100
  tags        = ["${local.name_prefix}-vm-${count.index + 1}"]
}
