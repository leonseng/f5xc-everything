resource "volterra_origin_pool" "iperf" {
  name                   = "${local.name_prefix}-iperf"
  namespace              = local.xc_namespace
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  no_tls                 = true
  port                   = "5201"
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
}

resource "volterra_tcp_loadbalancer" "iperf" {
  name                 = "${local.name_prefix}-iperf"
  namespace            = local.xc_namespace
  domains              = ["iperf.example.com"]
  listen_port          = 5201
  no_sni               = true
  no_service_policies  = true
  dns_volterra_managed = false

  origin_pools_weights {
    weight   = 1
    priority = 1

    pool {
      tenant    = var.xc_tenant_id
      namespace = local.xc_namespace
      name      = volterra_origin_pool.iperf.name
    }
  }

  advertise_custom {
    advertise_where {
      port = 5201
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
