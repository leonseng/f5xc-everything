variable "project_prefix" {
  description = "String to be prefixed to resources created"
  type = string
  default = "ws-proxy-chain-"
}

variable "region" {
  description = "Region to deploy AWS resources in"
  type        = string
  default     = "ap-southeast-2"
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}
