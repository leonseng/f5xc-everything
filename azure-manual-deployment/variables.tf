variable "project_prefix" {
  type = string
}

variable "azure_region" {
  type    = string
  default = "Australia East"
}

variable "azure_az_count" {
  type    = number
  default = 1
}

variable "azure_vnet_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azure_node_count" {
  type    = number
  default = 1
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

variable "azure_sp_app_id" {
  description = "Azure service principal Application ID"
  type        = string
}

variable "azure_sp_subscription_id" {
  description = "Azure service principal Subscription ID"
  type        = string
}

variable "azure_sp_tenant_id" {
  description = "Azure service principal Tenant ID"
  type        = string
}

variable "azure_sp_password" {
  description = "Azure service principal password"
  type        = string
}

variable "f5xc_api_p12_file" {
  description = "F5 XC API certificate file"
  type        = string
}

variable "f5xc_api_p12_cert_password" {
  description = "F5 XC API certificate file password"
  type        = string
  default     = ""
}

variable "f5xc_api_url" {
  description = "F5 XC API URL"
  type        = string
}

variable "f5xc_api_token" {
  description = "F5 XC API token"
  type        = string
  default     = ""
}

variable "f5xc_tenant" {
  description = "F5 XC Tenant name"
  type        = string
}

variable "f5xc_namespace" {
  description = "F5 XC namespace name"
  type        = string
  default     = "system"
}

variable "owner" {
  description = "Azure tag owner email address"
  type        = string
}

variable "azurerm_instance_admin_username" {
  type        = string
  description = "Azure VM instance username"
  default     = "operator"
}

variable "azurerm_disable_password_authentication" {
  type        = bool
  description = "Azure VM disable user password authentication"
  default     = true
}

variable "f5xc_ce_vm_size" {
  type    = string
  default = "Standard_D3_v2"
}

variable "f5xc_ce_gateway_type" {
  description = "F5 XC CE gateway type to set single NIC or multi NIC"
  type        = string
  default     = "ingress_egress_gateway"
}

variable "f5xc_cluster_latitude" {
  description = "F5 XC CE geo latitude"
  type        = number
}

variable "f5xc_cluster_longitude" {
  description = "F5 XC CE geo longitude"
  type        = number
}

variable "f5xc_ce_username" {
  type    = string
  default = "operator"
}

variable "f5xc_ce_password" {
  type    = string
  default = "Volterra123"
}
