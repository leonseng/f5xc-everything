# obtained from output of old terraform project
variable "name_prefix" {
  type = string
}

variable "f5xc_tenant_id" {
  type = string
}

variable "f5xc_api_p12_file" {
  description = "API credential p12 file path"
  type        = string
}

variable "f5xc_namespace" {
  description = "Namespaces to deploy app objects in"
  type        = string
}
