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

data "google_compute_zones" "available" {}

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
    no_global_network        = true
    no_dc_cluster_group      = true
    no_forward_proxy         = true
    no_inside_static_routes  = true
    no_network_policy        = true
    no_outside_static_routes = true
    sm_connection_public_ip  = true

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
