resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.object_name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.object_name_prefix}-igw"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "inside" {
  count = var.aws_az_count

  cidr_block        = cidrsubnet(cidrsubnet(var.aws_vpc_cidr, 4, 0), 4, count.index + 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.object_name_prefix}-inside-${count.index + 1}"
  }
}

resource "aws_subnet" "outside" {
  count = var.aws_az_count

  cidr_block              = cidrsubnet(cidrsubnet(var.aws_vpc_cidr, 4, 1), 4, count.index + 1)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.object_name_prefix}-outside-${count.index + 2}"
  }
}

resource "aws_route_table" "outside" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "outside" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.outside[count.index].id
  route_table_id = aws_route_table.outside.id
}

# resource "aws_security_group" "ce_slo" {
#   name        = "ce_slo"
#   description = "Allow TLS inbound"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "TLS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["10.0.0.0/16", "10.50.0.0/16"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "${var.object_name_prefix}-ce_slo"
#   }
# }

# resource "aws_security_group" "ce_sli" {
#   name        = "ce_sli"
#   description = "Allow any"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.object_name_prefix}-ce_sli"
#   }
# }
