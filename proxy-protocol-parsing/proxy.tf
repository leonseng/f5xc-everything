provider "kubectl" {
  config_path      = "${path.module}/tmp/${local.project_name}.kubeconfig"
  load_config_file = true
}

locals {
  server_name = "${local.project_name}.example.com"
}

resource "kubectl_manifest" "configmap" {
  depends_on = [
    local_file.kubeconfig
  ]

  override_namespace = local.project_name
  force_new          = true
  yaml_body          = file("${path.module}/files/configmap.yaml")
}

resource "kubectl_manifest" "deployment" {
  depends_on = [
    local_file.kubeconfig
  ]

  override_namespace = local.project_name
  force_new          = true
  yaml_body = templatefile("${path.module}/files/deployment.yaml.tftpl",
    {
      server_name = local.server_name,
      nginx_image = var.nginx_image
    }
  )
}

resource "kubectl_manifest" "service" {
  depends_on = [
    local_file.kubeconfig
  ]

  override_namespace = local.project_name
  force_new          = true
  yaml_body          = file("${path.module}/files/service.yaml")
}

## origin server
resource "volterra_origin_pool" "proxy" {
  depends_on = [
    volterra_virtual_site.re
  ]

  name                   = local.project_name
  namespace              = local.project_name
  port                   = 8080
  health_check_port      = 8080
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  no_tls                 = true

  origin_servers {
    k8s_service {
      vk8s_networks = true
      site_locator {
        virtual_site {
          tenant    = var.tenant_id
          name      = "${local.project_name}-re"
          namespace = local.project_name
        }
      }
      service_name = "nginx.${local.project_name}"
    }
  }
}

resource "volterra_tcp_loadbalancer" "proxy" {
  depends_on = [
    volterra_origin_pool.proxy
  ]

  name                            = local.project_name
  namespace                       = local.project_name
  tcp                             = true
  no_sni                          = true
  dns_volterra_managed            = false
  listen_port                     = 8080
  advertise_on_public_default_vip = true

  origin_pools_weights {
    pool {
      tenant    = var.tenant_id
      namespace = local.project_name
      name      = local.project_name
    }
    weight   = 1
    priority = 1
  }
}
