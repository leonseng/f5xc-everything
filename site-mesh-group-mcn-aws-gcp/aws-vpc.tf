resource "aws_vpc" "main" {
  cidr_block           = var.aws_vpc_cidr
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

locals {
  aws_inside_cidr    = cidrsubnet(var.aws_vpc_cidr, 4, 0)
  aws_outside_cidr   = cidrsubnet(var.aws_vpc_cidr, 4, 1)
  aws_workload_cidr  = cidrsubnet(var.aws_vpc_cidr, 4, 3)
  aws_vm_cidr        = cidrsubnet(var.aws_vpc_cidr, 4, 4)
  aws_inside_cidrs   = [for i in range(var.aws_az_count) : cidrsubnet(local.aws_inside_cidr, 4, i)]
  aws_outside_cidrs  = [for i in range(var.aws_az_count) : cidrsubnet(local.aws_outside_cidr, 4, i)]
  aws_workload_cidrs = [for i in range(var.aws_az_count) : cidrsubnet(local.aws_workload_cidr, 4, i)]
  aws_vm_cidrs       = [for i in range(var.aws_az_count) : cidrsubnet(local.aws_vm_cidr, 4, i)]
}

resource "aws_subnet" "inside" {
  count = var.aws_az_count

  cidr_block        = local.aws_inside_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-inside-${count.index + 1}"
  }
}

resource "aws_subnet" "outside" {
  count = var.aws_az_count

  cidr_block              = local.aws_outside_cidrs[count.index]
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-outside-${count.index + 2}"
  }
}

resource "aws_subnet" "workload" {
  count = var.aws_az_count

  cidr_block        = local.aws_workload_cidrs[count.index]
  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-workload-${count.index + 1}"
  }
}

### Workload
resource "aws_subnet" "vm" {
  count = var.aws_az_count

  cidr_block              = local.aws_vm_cidrs[count.index]
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-vm-${count.index + 1}"
  }
}

resource "aws_route_table" "vm" {
  count = var.aws_az_count

  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name_prefix}-vm-${count.index}"
  }
}

resource "aws_route_table_association" "vm" {
  count = var.aws_az_count

  subnet_id      = aws_subnet.vm[count.index].id
  route_table_id = aws_route_table.vm[count.index].id
}

resource "aws_route" "vm_default" {
  count = var.aws_az_count

  route_table_id         = aws_route_table.vm[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_security_group" "vm" {
  name        = "${local.name_prefix}-vm"
  description = "Allow SSH, HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr, "${local.my_ip}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1 # All ICMP codes
    to_port     = -1 # All ICMP codes
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-vm"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "ssh_access" {
  public_key = var.ssh_public_key
}

resource "aws_instance" "vm" {
  count         = var.aws_az_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.ssh_access.key_name
  subnet_id     = aws_subnet.vm[count.index].id
  user_data = templatefile("${path.module}/files/vm/cloud-config", {
    run_script = base64encode(file("${path.module}/files/vm/run.sh"))
    nginx_conf = base64encode(file("${path.module}/files/vm/nginx.conf"))
  })

  vpc_security_group_ids = [
    aws_security_group.vm.id
  ]

  tags = {
    Name = "${local.name_prefix}-vm-${count.index + 1}"
  }
}

resource "aws_instance" "vm-workload" {
  count         = var.aws_az_count
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.ssh_access.key_name
  subnet_id     = aws_subnet.workload[count.index].id
  user_data = templatefile("${path.module}/files/vm/cloud-config", {
    run_script = base64encode(file("${path.module}/files/vm/run.sh"))
    nginx_conf = base64encode(file("${path.module}/files/vm/nginx.conf"))
  })

  vpc_security_group_ids = [
    aws_security_group.vm.id
  ]

  tags = {
    Name = "${local.name_prefix}-vm-${count.index + 1}"
  }
}

output "aws_vpc_id" {
  value = aws_vpc.main.id
}

output "aws_igw_id" {
  value = aws_internet_gateway.this.id
}

output "aws_sg_ce_slo" {
  value = aws_security_group.ce_slo.id
}

output "aws_sg_ce_sli" {
  value = aws_security_group.ce_sli.id
}

output "aws_outside_subnets" {
  value = aws_subnet.outside[*].id
}

output "aws_inside_subnets" {
  value = aws_subnet.inside[*].id
}

output "aws_workload_subnets" {
  value = aws_subnet.workload[*].id
}

output "aws_vms" {
  value = aws_instance.vm[*].public_dns
}
