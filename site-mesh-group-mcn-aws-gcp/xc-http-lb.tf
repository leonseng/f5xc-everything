resource "volterra_healthcheck" "nginx" {
  name      = "${local.name_prefix}-nginx"
  namespace = local.xc_namespace

  http_health_check {
    use_http2              = false
    use_origin_server_name = true
    path                   = "/"
    expected_status_codes  = ["200"]
  }

  healthy_threshold   = 2
  interval            = 10
  timeout             = 1
  unhealthy_threshold = 5
}

resource "volterra_origin_pool" "nginx" {
  name                   = "${local.name_prefix}-nginx"
  namespace              = local.xc_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  no_tls                 = true
  port                   = "80"
  same_as_endpoint_port  = true

  origin_servers {
    dynamic "private_ip" {
      for_each = google_compute_instance.vm
      content {
        ip             = private_ip.value["network_interface"][0].network_ip
        inside_network = true

        site_locator {
          site {
            tenant    = var.xc_tenant_id
            namespace = "system"
            name      = volterra_gcp_vpc_site.this.name
          }
        }
      }
    }
  }

  healthcheck {
    tenant    = var.xc_tenant_id
    namespace = local.xc_namespace
    name      = volterra_healthcheck.nginx.name
  }
}

resource "volterra_http_loadbalancer" "nginx" {
  name                             = "${local.name_prefix}-nginx"
  namespace                        = local.xc_namespace
  domains                          = ["nginx.example.com"]
  disable_api_definition           = true
  disable_api_discovery            = true
  no_challenge                     = true
  disable_ddos_detection           = true
  round_robin                      = true
  disable_malicious_user_detection = true
  disable_rate_limit               = true
  no_service_policies              = true
  disable_trust_client_ip_headers  = true
  user_id_client_ip                = true
  disable_waf                      = true

  http {
    dns_volterra_managed = false
    port                 = "80"
  }

  default_route_pools {
    weight   = 1
    priority = 1

    pool {
      tenant    = var.xc_tenant_id
      namespace = local.xc_namespace
      name      = volterra_origin_pool.nginx.name
    }
  }

  advertise_custom {
    advertise_where {
      site {
        network = "SITE_NETWORK_INSIDE"
        site {
          tenant    = var.xc_tenant_id
          namespace = "system"
          name      = volterra_aws_vpc_site.this.name
        }
      }
    }
  }
}
