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

variable "object_name_prefix" {
  type = string
}
