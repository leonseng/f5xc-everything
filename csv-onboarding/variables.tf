variable "project_name" {
  type    = string
  default = "csv-onboarding"
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

variable "f5xc_app_virtual_site" {
  description = "Namespaces to deploy app objects in"
  type        = string
}

variable "f5xc_default_app_cert" {
  type = string
}

variable "f5xc_default_app_fw" {
  type = string
}
