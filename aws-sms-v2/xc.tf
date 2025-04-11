resource "volterra_securemesh_site_v2" "aws" {
  name      = local.name_prefix
  namespace = "system"

  aws {
      not_managed {}
  }

  block_all_services = true
  logs_streaming_disabled = true
  no_s2s_connectivity_sli = true
  no_s2s_connectivity_slo = true
  no_network_policy = true
  no_forward_proxy = true
  enable_ha = var.aws_az_count==1 ? null : true
  disable_ha = var.aws_az_count==1 ? true : null
  f5_proxy = true

  software_settings {
    sw {
      default_sw_version = true
    }
    os {
      default_os_version = true
    }
  }

  upgrade_settings {
    kubernetes_upgrade_drain {
      enable_upgrade_drain {
        drain_node_timeout = 300
        drain_max_unavailable_node_count = 1
      }
    }
  }

  performance_enhancement_mode {
    perf_mode_l7_enhanced = true
  }

  offline_survivability_mode {
    enable_offline_survivability_mode = true
  }

  load_balancing {
    vip_vrrp_mode = "VIP_VRRP_DISABLE"
  }

  local_vrf {
    default_config  = true
    default_sli_config  = true
  }

  re_select {
    geo_proximity = true
  }


  admin_user_credentials {
    ssh_key = var.ssh_public_key
    admin_password {
      blindfold_secret_info {
        location = var.f5xc_ce_blindfolded_admin_password
      }
    }
  }

  proactive_monitoring {
    proactive_monitoring_enable = true
  }
  dns_ntp_config {
    f5_dns_default = true
    f5_ntp_default = true
  }
}

resource "volterra_token" "nodes" {
  depends_on = [ volterra_securemesh_site_v2.aws ]
  count = var.aws_az_count

  name      = "${local.name_prefix}-token-${count.index}"
  namespace = "system"
  type = 1  # JWT
  site_name = volterra_securemesh_site_v2.aws.name
}
