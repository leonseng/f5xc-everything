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

variable "nginx_image" {
  type    = string
  default = "macbre/nginx-http3:latest"
}
