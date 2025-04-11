variable "aws_region" {
  type = string
}

variable "aws_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "aws_az_count" {
  type    = number
  default = 1
}

variable "project_name" {
  type    = string
  default = "aws-vpc"
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

variable "f5xc_tenant" {
  description = "Tenant name"
  type        = string
}

variable "f5xc_api_url" {
  description = "Tenant API url"
  type        = string
}

variable "f5xc_api_token" {
  type      = string
  sensitive = true
}

variable "f5xc_api_p12_file" {
  description = "API credential p12 file path"
  type        = string
}

variable "f5xc_ce_instance_type" {
  type = string
}

variable "f5xc_cluster_latitude" {
  type = string
}

variable "f5xc_cluster_longitude" {
  type = string
}

variable "owner_tag" {
  type = string
}

variable "f5xc_ce_blindfolded_admin_password" {
  type      = string
  sensitive = true
}