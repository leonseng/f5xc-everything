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

resource "kubectl_manifest" "secret" {
  depends_on = [
    local_file.kubeconfig
  ]

  override_namespace = local.project_name
  force_new          = true
  yaml_body = templatefile("${path.module}/files/secret.yaml.tftpl",
    {
      nginx_plus_registry_secret = var.nginx_plus_registry_secret
    }
  )
}

resource "kubectl_manifest" "deployment" {
  depends_on = [
    local_file.kubeconfig
  ]

  override_namespace = local.project_name
  force_new          = true
  yaml_body = templatefile("${path.module}/files/deployment.yaml.tftpl",
    {
      nginx_plus_image = var.nginx_plus_image
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

resource "volterra_origin_pool" "proxy" {
  depends_on = [
    volterra_virtual_site.re
  ]

  name                   = local.project_name
  namespace              = local.project_name
  port                   = 8080
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

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

## HTTP LB
resource "volterra_http_loadbalancer" "proxy" {
  depends_on = [
    volterra_origin_pool.proxy
  ]

  name                            = local.project_name
  namespace                       = local.project_name
  domains                         = ["${local.project_name}.example.com"]
  advertise_on_public_default_vip = true
  disable_bot_defense             = true
  disable_ip_reputation           = true
  disable_client_side_defense     = true

  http {
    dns_volterra_managed = false
    port                 = 8080
  }

  default_route_pools {
    pool {
      tenant    = var.tenant_id
      namespace = local.project_name
      name      = local.project_name
    }
    weight   = 1
    priority = 1
  }
}

data "volterra_http_loadbalancer_state" "proxy" {
  depends_on = [
    volterra_http_loadbalancer.proxy
  ]
  name      = local.project_name
  namespace = local.project_name
}
