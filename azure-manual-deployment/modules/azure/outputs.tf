output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "vnet" {
  value = azurerm_virtual_network.this.name
}

output "outside_subnet" {
  value = azurerm_subnet.outside.name
}

output "inside_subnet" {
  value = azurerm_subnet.inside.name
}
