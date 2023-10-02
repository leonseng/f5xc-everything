resource "volterra_virtual_network" "global" {
  name      = "${local.name_prefix}-global"
  namespace = "system"

  global_network = true
}

resource "volterra_virtual_site" "this" {
  name      = local.name_prefix
  namespace = "shared"
  site_type = "CUSTOMER_EDGE"

  site_selector {
    expressions = ["deployment_id == ${local.name_prefix}"]
  }
}

resource "volterra_site_mesh_group" "this" {
  name      = local.name_prefix
  namespace = "system"

  virtual_site {
    tenant    = var.xc_tenant_id
    namespace = "shared"
    name      = local.name_prefix
  }

  full_mesh {
    data_plane_mesh = true
  }
}

resource "volterra_network_interface" "inside" {
  name      = "${local.name_prefix}-inside"
  namespace = "system"

  ethernet_interface {
    device                    = "eth1" # inside
    dhcp_client               = true
    cluster                   = true
    untagged                  = true
    site_local_inside_network = true
    not_primary               = true
  }
}

locals {
  xc_namespace = (var.xc_namespace == "") ? local.name_prefix : var.xc_namespace
}

resource "volterra_namespace" "this" {
  count = var.xc_create_namespace ? 1 : 0

  name = local.xc_namespace
}
