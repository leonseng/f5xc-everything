resource "volterra_virtual_site" "re" {
  depends_on = [
    volterra_namespace.this
  ]

  name      = "${local.project_name}-re"
  namespace = local.project_name

  site_selector {
    expressions = ["ves.io/country in (ves-io-au)"]
  }

  site_type = "REGIONAL_EDGE"
}

resource "volterra_virtual_k8s" "this" {
  depends_on = [
    volterra_virtual_site.re
  ]

  name      = local.project_name
  namespace = local.project_name

  vsite_refs {
    tenant    = var.tenant_id
    namespace = local.project_name
    name      = "${local.project_name}-re"
  }
}

resource "time_sleep" "wait_for_vk8s" {
  depends_on = [
    volterra_virtual_k8s.this
  ]

  create_duration = "90s"
}

resource "volterra_api_credential" "this" {
  depends_on = [
    time_sleep.wait_for_vk8s
  ]

  name                  = local.project_name
  api_credential_type   = "KUBE_CONFIG"
  virtual_k8s_namespace = local.project_name
  virtual_k8s_name      = local.project_name
  expiry_days           = 30
}

resource "local_file" "kubeconfig" {
  content  = base64decode(volterra_api_credential.this.data)
  filename = "${path.module}/tmp/${local.project_name}.kubeconfig"
}
