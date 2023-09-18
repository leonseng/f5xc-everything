
data "aws_ami" "ubuntu_20_04" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_key_pair" "ssh_access" {
  public_key = var.ssh_public_key
}

resource "aws_security_group" "apigw" {
  name   = "${random_id.id.dec}-apigw"
  vpc_id = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.my_ip}/32"]
  }

  ingress {
    description = "websocket"
    from_port   = 8020
    to_port     = 8020
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0", local.vpc_cidr]
  }

  ingress {
    description = "ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0", local.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "nginx" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ssh_access.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.apigw.id]
  user_data = templatefile(
    "${path.module}/files/cloud-init.yaml.tpl",
    {
      bootstrap_b64      = base64encode(file("${path.module}/files/bootstrap.sh"))
      docker_compose_b64 = base64encode(file("${path.module}/files/docker-compose.yaml"))
      nginx_conf_b64     = base64encode(file("${path.module}/files/nginx.conf"))
    }
  )
}

output "nginx_fqdn" {
  value = aws_instance.nginx.public_dns
}
