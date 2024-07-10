variable "azure_region" {
  type    = string
  default = "Australia East"
}

variable "azure_vnet_cidr" {
  type = string
}

variable "azure_az_count" {
  type    = number
  default = 1
}

variable "project_name" {
  type = string
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

# variable "azure_sp_app_id" {
#   description = "Azure service principal Application ID"
#   type        = string
# }

# variable "azure_sp_subscription_id" {
#   description = "Azure service principal Subscription ID"
#   type        = string
# }

# variable "azure_sp_tenant_id" {
#   description = "Azure service principal Tenant ID"
#   type        = string
# }

# variable "azure_sp_password" {
#   description = "Azure service principal password"
#   type        = string
# }
