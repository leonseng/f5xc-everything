resource "volterra_http_loadbalancer" "app" {
  depends_on = [
    volterra_origin_pool.httpbin,
    volterra_certificate.example
  ]

  name                             = local.name_prefix
  namespace                        = var.f5xc_namespace
  domains                          = [for i in range(0, var.origin_count) : "httpbin-${i}.example.com"] // max domains per LB: 32. Use wildcard domains if more is required
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
    ddos_policy_none = false
    mitigation_block = true
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

      dynamic "certificates" { // max certs per LB: 32. Use wildcard domains if more is required
        for_each = range(0, var.origin_count)
        content {
          tenant    = var.f5xc_tenant_id
          namespace = var.f5xc_namespace
          name      = "${local.name_prefix}-httpbin-${certificates.value}"
        }
      }

    }
  }

  dynamic "routes" {
    for_each = range(0, var.origin_count)

    content {
      simple_route {
        http_method = "ANY"

        path {
          prefix = "/"
        }

        auto_host_rewrite = true

        headers {
          # name  = "X-Envoy-Original-Authority"  // doesn't work
          name  = "host"
          exact = "httpbin-${routes.value}.example.com"
        }

        origin_pools {
          pool {
            tenant    = var.f5xc_tenant_id
            namespace = var.f5xc_namespace
            name      = volterra_origin_pool.httpbin.name
          }
        }

        advanced_options {
          common_buffering          = true
          common_hash_policy        = true
          default_retry_policy      = true
          disable_mirroring         = true
          disable_prefix_rewrite    = true
          disable_spdy              = true
          disable_web_socket_config = true
          priority                  = "DEFAULT"
          retract_cluster           = true

          request_headers_to_add {
            name   = "x-overload-route"
            value  = "route-${routes.value}"
            append = false
          }
        }
      }

    }
  }
}
