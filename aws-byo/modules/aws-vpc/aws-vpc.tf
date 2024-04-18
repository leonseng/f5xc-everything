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

resource "aws_subnet" "dmz" {
  count = var.aws_az_count

  cidr_block              = cidrsubnet(cidrsubnet(var.aws_vpc_cidr, 4, 2), 4, count.index + 1)
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.object_name_prefix}-dmz-${count.index + 2}"
  }
}

resource "aws_eip" "natgw" {}

resource "aws_nat_gateway" "this" {
  depends_on = [aws_internet_gateway.this]

  allocation_id = aws_eip.natgw.id
  subnet_id     = aws_subnet.dmz[0].id

  tags = {
    Name = "${var.object_name_prefix}-natgw"
  }
}

resource "aws_route_table" "dmz" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "dmz" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.dmz[count.index].id
  route_table_id = aws_route_table.dmz.id
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

  cidr_block        = cidrsubnet(cidrsubnet(var.aws_vpc_cidr, 4, 1), 4, count.index + 1)
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.object_name_prefix}-outside-${count.index + 2}"
  }
}

resource "aws_route_table" "outside" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "outside" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.outside[count.index].id
  route_table_id = aws_route_table.outside.id
}
