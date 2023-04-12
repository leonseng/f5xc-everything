variable "project_name" {
  type = string
}

variable "tenant_id" {
  description = "Tenant ID. Found in Administration > Tenant Information"
  type        = string
}

variable "api_endpoint" {
  description = "Tenant API url"
  type        = string
}

variable "api_p12_file" {
  description = "API credential p12 file path"
  type        = string
}

variable "ca_cert_file" {
  type = string
}

variable "ca_key_file" {
  type = string
}

variable "nginx_plus_registry_secret" {
  description = "Base64 encoded string of Docker config containing credentials to authenticate with a container registry to pull NGINX Plus image"
  type        = string
  default     = null
}

variable "nginx_plus_image" {
  type = string
}
