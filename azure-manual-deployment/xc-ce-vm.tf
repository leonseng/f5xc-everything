# https://docs.cloud.f5.com/docs/how-to/site-management/deploy-site-azure-clickops

resource "azurerm_network_security_group" "ce" {
  name                = local.project_name
  location            = module.azure.location
  resource_group_name = module.azure.resource_group

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${local.my_ip}/32"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowTCP65500"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65500"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_ssh_public_key" "ce" {
  name                = local.project_name
  location            = module.azure.location
  resource_group_name = module.azure.resource_group
  public_key          = var.ssh_public_key
}

resource "azurerm_public_ip" "slo" {
  count = var.azure_az_count

  name                = "${local.project_name}-${count.index}"
  location            = module.azure.location
  resource_group_name = module.azure.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [count.index + 1]
}

resource "azurerm_network_interface" "slo" {
  count = var.azure_az_count

  name                = "${local.project_name}-slo-${count.index}"
  location            = module.azure.location
  resource_group_name = module.azure.resource_group

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "slo"
    subnet_id                     = data.azurerm_subnet.outside.id
    public_ip_address_id          = azurerm_public_ip.slo[count.index].id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(data.azurerm_subnet.outside.address_prefix, (count.index * 2) + 10)
  }
}

resource "azurerm_network_interface" "sli" {
  count = var.azure_az_count

  name                = "${local.project_name}-inside-${count.index}"
  location            = module.azure.location
  resource_group_name = module.azure.resource_group

  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "sli"
    subnet_id                     = data.azurerm_subnet.inside.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(data.azurerm_subnet.inside.address_prefix, (count.index * 2) + 11)
  }
}

resource "azurerm_storage_account" "ce" {
  count = var.azure_az_count

  name                     = replace("${local.project_name}-${count.index}", "-", "")
  location                 = module.azure.location
  resource_group_name      = module.azure.resource_group
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine" "ce" {
  count = var.azure_az_count

  name                  = "${local.project_name}-${count.index}"
  zone                  = count.index + 1
  location              = module.azure.location
  resource_group_name   = module.azure.resource_group
  network_interface_ids = [azurerm_network_interface.slo[count.index].id, azurerm_network_interface.sli[count.index].id]
  size                  = var.f5xc_ce_vm_size
  computer_name         = "${local.project_name}-${count.index}"
  custom_data = base64encode(
    templatefile(
      "${path.module}/files/f5-ce-data.yml",
      {
        cluster_name = "${local.project_name}-${count.index}"
        token        = volterra_token.this.id
      }
    )
  )
  disable_password_authentication = false
  admin_username                  = var.f5xc_ce_username
  admin_password                  = var.f5xc_ce_password
  tags = {
    "Owner" = var.owner
  }

  admin_ssh_key {
    username   = var.f5xc_ce_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = 100
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    sku       = "freeplan_entcloud_voltmesh_voltstack_node_multinic"
    offer     = "entcloud_voltmesh_voltstack_node"
    version   = "latest"
    publisher = "volterraedgeservices"
  }

  plan {
    name      = "freeplan_entcloud_voltmesh_voltstack_node_multinic"
    product   = "entcloud_voltmesh_voltstack_node"
    publisher = "volterraedgeservices"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.ce[count.index].primary_blob_endpoint
  }
}
