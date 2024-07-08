provider "aws" {
  region = var.aws_region
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  my_ip = chomp(data.http.myip.response_body)
}
