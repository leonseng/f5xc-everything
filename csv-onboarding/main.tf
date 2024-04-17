locals {
  apps = csvdecode(file("${path.module}/input.csv"))
}

resource "volterra_healthcheck" "basic" {
  name      = "basic"
  namespace = var.f5xc_namespace

  http_health_check {
    use_http2              = false
    use_origin_server_name = true
    path                   = "/"
    expected_status_codes  = ["200-399"]
  }

  healthy_threshold   = 2
  interval            = 10
  timeout             = 1
  unhealthy_threshold = 5
}

resource "volterra_origin_pool" "backend" {
  depends_on = [
    volterra_healthcheck.basic
  ]

  for_each = tomap({ for app in local.apps : app.name => app })

  name                   = each.key
  namespace              = var.f5xc_namespace
  port                   = 443
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  use_tls {
    use_host_header_as_sni   = true
    skip_server_verification = true
    no_mtls                  = true
    tls_config {
      low_security = true
    }
  }

  healthcheck {
    tenant    = var.f5xc_tenant_id
    namespace = var.f5xc_namespace
    name      = volterra_healthcheck.basic.name
  }

  origin_servers {
    private_name {
      dns_name         = each.value.origin_pool_dns
      refresh_interval = 300
      inside_network   = true
      site_locator {
        virtual_site {
          tenant    = var.f5xc_tenant_id
          namespace = var.f5xc_namespace
          name      = var.f5xc_app_virtual_site
        }
      }
    }
  }
}

resource "volterra_http_loadbalancer" "app" {
  depends_on = [
    volterra_origin_pool.backend
  ]

  for_each = tomap({ for app in local.apps : app.name => app })

  name      = each.key
  namespace = var.f5xc_namespace
  domains   = [each.value.domain]

  https {
    http_redirect = true
    port          = 443
    tls_cert_params {
      no_mtls = true

      tls_config {
        default_security = true
      }

      certificates {
        tenant    = var.f5xc_tenant_id
        namespace = var.f5xc_namespace
        name      = var.f5xc_default_app_cert
      }
    }
  }

  routes {
    simple_route {
      path {
        prefix = "/"
      }

      origin_pools {
        pool {
          tenant    = var.f5xc_tenant_id
          namespace = var.f5xc_namespace
          name      = each.key
        }
      }
    }
  }

  app_firewall {
    tenant    = var.f5xc_tenant_id
    namespace = var.f5xc_namespace
    name      = var.f5xc_default_app_fw
  }

  advertise_custom {
    advertise_where {
      dynamic "site" {
        for_each = split(";", each.value.advertise_sites)
        content {
          ip      = each.value.vip
          network = "SITE_NETWORK_OUTSIDE"
          site {
            tenant    = var.f5xc_tenant_id
            namespace = "system"
            name      = site.value
          }
        }
      }
    }
  }

}
