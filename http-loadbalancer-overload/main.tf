resource "volterra_http_loadbalancer" "app" {
  depends_on = [
    volterra_origin_pool.httpbin,
    volterra_certificate.example
  ]

  name                            = local.name_prefix
  namespace                       = var.f5xc_namespace
  domains                         = [for i in range(0, var.origin_count) : "httpbin-${i}.example.com"]
  advertise_on_public_default_vip = true

  https {
    http_redirect = true
    port          = 443
    tls_cert_params {
      no_mtls = true

      tls_config {
        default_security = true
      }

      dynamic "certificates" {
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
