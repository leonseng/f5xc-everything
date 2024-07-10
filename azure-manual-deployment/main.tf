resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_prefix}-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  project_name = random_id.id.dec
  my_ip        = chomp(data.http.myip.response_body)
}

module "azure" {
  source = "./modules/azure"

  project_name    = local.project_name
  azure_region    = var.azure_region
  azure_vnet_cidr = var.azure_vnet_cidr
  azure_az_count  = var.azure_az_count
  ssh_public_key  = var.ssh_public_key
}

data "azurerm_virtual_network" "example" {
  name                = module.azure.vnet
  resource_group_name = module.azure.resource_group
}

data "azurerm_subnet" "outside" {
  name                 = module.azure.outside_subnet
  virtual_network_name = module.azure.vnet
  resource_group_name  = module.azure.resource_group
}

data "azurerm_subnet" "inside" {
  name                 = module.azure.inside_subnet
  virtual_network_name = module.azure.vnet
  resource_group_name  = module.azure.resource_group
}
