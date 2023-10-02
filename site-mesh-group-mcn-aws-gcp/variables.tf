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

variable "aws_vm_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_inside_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "gcp_outside_vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "gcp_zone_count" {
  type    = number
  default = 1
}

variable "gcp_vm_machine_type" {
  type    = string
  default = "e2-micro"
}

variable "project_name" {
  type    = string
  default = "aws-vpc"
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

variable "xc_aws_access_key" {
  description = "AWS access key for deploying CE site"
  type        = string
}

variable "xc_aws_secret_key" {
  description = "AWS secret key for deploying CE site"
  type        = string
}

variable "xc_aws_ce_instance_type" {
  type    = string
  default = "t3.xlarge"
}

variable "xc_gcp_ce_machine_type" {
  type    = string
  default = "n1-standard-4"
}

variable "xc_namespace" {
  type    = string
  default = ""
}

variable "xc_create_namespace" {
  type    = bool
  default = false
}
