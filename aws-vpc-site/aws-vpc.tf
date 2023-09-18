resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "inside" {
  count = var.az_count

  cidr_block        = cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 0), 4, count.index + 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-inside-${count.index + 1}"
  }
}

resource "aws_subnet" "outside" {
  count = var.az_count

  cidr_block              = cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 1), 4, count.index + 1)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-outside-${count.index + 2}"
  }
}

resource "aws_subnet" "workload" {
  count = var.az_count

  cidr_block        = cidrsubnet(cidrsubnet(var.vpc_cidr, 4, 3), 4, count.index + 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-workload-${count.index + 1}"
  }
}

resource "aws_security_group" "ce_slo" {
  name        = "ce_slo"
  description = "Allow TLS inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16", "10.50.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ce_slo"
  }
}

resource "aws_security_group" "ce_sli" {
  name        = "ce_sli"
  description = "Allow any"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ce_sli"
  }
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "igw_id" {
  value = aws_internet_gateway.this.id
}

output "sg_ce_slo" {
  value = aws_security_group.ce_slo.id
}

output "sg_ce_sli" {
  value = aws_security_group.ce_sli.id
}

output "outside_subnets" {
  value = aws_subnet.outside[*].id
}

output "inside_subnets" {
  value = aws_subnet.inside[*].id
}

output "workload_subnets" {
  value = aws_subnet.workload[*].id
}
