resource "azurerm_resource_group" "this" {
  name     = var.project_name
  location = var.azure_region
}

resource "azurerm_virtual_network" "this" {
  name                = var.project_name
  address_space       = [var.azure_vnet_cidr]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "outside" {
  name                 = "${var.project_name}-outside"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.azure_vnet_cidr, 8, 2)]
}

resource "azurerm_subnet" "inside" {
  name                 = "${var.project_name}-inside"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.azure_vnet_cidr, 8, 3)]
}
