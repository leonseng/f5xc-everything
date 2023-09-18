variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_inside_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "gcp_outside_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "gcp_zone_count" {
  type    = number
  default = 1
}

variable "project_name" {
  type    = string
  default = "gcp-vpc"
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

variable "xc_api_endpoint" {
  description = "Tenant API url"
  type        = string
}

variable "xc_api_p12_file" {
  description = "API credential p12 file path"
  type        = string
}

variable "xc_tenant_id" {
  description = "XC Tenant ID. Found under Administration > Tenant Settings > Tenant Overview"
  type        = string
}
