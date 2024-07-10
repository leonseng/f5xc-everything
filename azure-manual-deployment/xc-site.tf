resource "volterra_token" "this" {
  name      = local.project_name
  namespace = "system"
}

resource "volterra_securemesh_site" "secure_mesh_site" {
  count = var.azure_az_count

  name                  = "${local.project_name}-${count.index}"
  namespace             = "system"
  volterra_certified_hw = "azure-byol-multi-nic-voltmesh"

  coordinates {
    latitude  = var.f5xc_cluster_latitude
    longitude = var.f5xc_cluster_longitude
  }

  offline_survivability_mode {
    enable_offline_survivability_mode = true
  }

  performance_enhancement_mode {
    perf_mode_l7_enhanced = true
  }

  master_node_configuration {
    name = "master-0"
  }

  custom_network_config {
    interface_list {
      interfaces {
        description = "slo"
        ethernet_interface {
          device = "eth0"
        }
      }

      interfaces {
        description = "sli"
        ethernet_interface {
          device = "eth1"
        }
      }
    }
  }
}

resource "volterra_registration_approval" "nodes" {
  depends_on = [azurerm_linux_virtual_machine.ce]
  count      = var.azure_az_count

  cluster_name = "${local.project_name}-${count.index}"
  cluster_size = 1
  retry        = 20
  hostname     = azurerm_linux_virtual_machine.ce[count.index].name
  wait_time    = 60

}

resource "volterra_site_state" "decommission_when_delete" {
  depends_on = [volterra_registration_approval.nodes]
  count      = var.azure_az_count

  name      = "${local.project_name}-${count.index}"
  when      = "delete"
  state     = "DECOMMISSIONING"
  retry     = 20
  wait_time = 60
}
