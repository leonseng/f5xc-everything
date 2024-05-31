variable "project_name" {
  type    = string
  default = "http-lb-overload"
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

variable "origin_count" {
  description = "Number of domains to overload on HTTP LB. Maximum of 32 domains/certs supported per LB. Use wildcard domains if more is required"
  type        = number
  default     = 2
}
