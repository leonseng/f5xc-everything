resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_name}-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

resource "time_static" "this" {}

locals {
  name_prefix = random_id.id.dec
  my_ip       = chomp(data.http.myip.response_body)
}

# look for AWS AMI that starts with f5xc-ce-* and select the latest one by creation date
data "aws_ami" "f5xc_ce" {
  most_recent = true

  owners = ["434481986642"]  # F5 XC AMI owner ID

  filter {
    name   = "name"
    values = ["f5xc-ce-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

output "AMI" {
  value = data.aws_ami.f5xc_ce.id

}

module "aws_vpc" {
  source = "../modules/aws-vpc"

  aws_region         = var.aws_region
  aws_az_count       = var.aws_az_count
  object_name_prefix = local.name_prefix
}

resource "aws_key_pair" "key" {
  key_name   = local.name_prefix
  public_key = var.ssh_public_key
}

resource "aws_security_group" "outside" {
  name        = "${local.name_prefix}-outside"
  vpc_id      = module.aws_vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "inside" {
  name        = "${local.name_prefix}-inside"
  vpc_id      = module.aws_vpc.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_network_interface" "outside" {
  count                  = var.aws_az_count

  subnet_id               = module.aws_vpc.node_subnets[count.index].outside_subnet
  security_groups         = [aws_security_group.outside.id]
  source_dest_check       = false
}

resource "aws_eip" "eip" {
  count             = var.aws_az_count
  network_interface = aws_network_interface.outside[count.index].id
}

resource "aws_network_interface" "inside" {
  count                  = var.aws_az_count

  subnet_id               = module.aws_vpc.node_subnets[count.index].inside_subnet
  security_groups         = [aws_security_group.inside.id]
  source_dest_check       = false
}

resource "aws_instance" "ce" {
  count             = var.aws_az_count
  ami               = data.aws_ami.f5xc_ce.id
  instance_type     = var.f5xc_ce_instance_type
  key_name          = aws_key_pair.key.key_name
  user_data_base64     = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
    token = volterra_token.nodes[count.index].id
  }))

  root_block_device {
    volume_size = 100
  }

  network_interface {
    network_interface_id = aws_network_interface.outside[count.index].id
    device_index         = "0"
  }

  network_interface {
    network_interface_id = aws_network_interface.inside[count.index].id
    device_index         = "1"
  }

  tags = {
    Name = "${local.name_prefix}-${count.index}"
    ves-io-site-name = local.name_prefix
    "kubernetes.io/cluster/${local.name_prefix}" = "owned"
    Owner = var.owner_tag
  }
}
