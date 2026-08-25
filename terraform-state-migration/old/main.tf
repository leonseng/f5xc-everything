resource "volterra_http_loadbalancer" "app" {
  depends_on = [
    volterra_origin_pool.httpbin,
    volterra_certificate.example
  ]

  name                             = local.name_prefix
  namespace                        = var.f5xc_namespace
  domains                          = ["httpbin.example.com"]
  advertise_on_public_default_vip  = true
  default_sensitive_data_policy    = true
  disable_api_definition           = true
  disable_api_discovery            = true
  disable_malicious_user_detection = true
  disable_malware_protection       = true
  disable_rate_limit               = true
  disable_threat_mesh              = true
  disable_trust_client_ip_headers  = true
  disable_api_testing              = true
  disable_waf                      = true
  no_challenge                     = true
  round_robin                      = true
  no_service_policies              = true
  user_id_client_ip                = true

  l7_ddos_protection {
    clientside_action_none = false
    ddos_policy_none       = false
    default_rps_threshold  = false
    mitigation_block       = false
    rps_threshold          = 0
  }

  https {
    enable_path_normalize = true
    http_redirect         = true
    port                  = 443
    tls_cert_params {
      no_mtls = true

      tls_config {
        default_security = true
      }

      certificates {
        tenant    = var.f5xc_tenant_id
        namespace = var.f5xc_namespace
        name      = "${local.name_prefix}-httpbin"

      }

    }
  }

  routes {
    route_state_enabled = true

    simple_route {
      http_method = "ANY"

      path {
        prefix = "/"
      }

      auto_host_rewrite = true

      headers {
        name  = "host"
        exact = "httpbin.example.com"
      }

      origin_pools {
        pool {
          tenant    = var.f5xc_tenant_id
          namespace = var.f5xc_namespace
          name      = volterra_origin_pool.httpbin.name
        }
      }
    }
  }
}
