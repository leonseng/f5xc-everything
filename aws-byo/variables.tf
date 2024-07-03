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

variable "project_name" {
  type    = string
  default = "aws-vpc"
}

variable "ssh_public_key" {
  description = "SSH public key to be loaded onto all EC2 instances for SSH access"
  type        = string
}

variable "f5xc_tenant" {
  description = "Tenant name"
  type        = string
}

variable "f5xc_api_url" {
  description = "Tenant API url"
  type        = string
}

variable "f5xc_api_token" {
  type      = string
  sensitive = true
}

variable "xc_api_p12_file" {
  description = "API credential p12 file path"
  type        = string
}

variable "f5xc_ce_machine_image" {
  type = object({
    ingress_gateway = object({
      af-south-1     = string
      ap-south-1     = string
      eu-north-1     = string
      eu-west-3      = string
      eu-south-1     = string
      eu-west-2      = string
      eu-west-1      = string
      ap-northeast-3 = string
      ap-northeast-2 = string
      me-south-1     = string
      ap-northeast-1 = string
      ca-central-1   = string
      sa-east-1      = string
      ap-east-1      = string
      ap-southeast-1 = string
      ap-southeast-2 = string
      eu-central-1   = string
      ap-southeast-3 = string
      us-east-1      = string
      us-east-2      = string
      us-west-1      = string
      us-west-2      = string
    })
    ingress_egress_gateway = object({
      af-south-1     = string
      ap-south-1     = string
      eu-north-1     = string
      eu-west-3      = string
      eu-south-1     = string
      eu-west-2      = string
      eu-west-1      = string
      ap-northeast-3 = string
      ap-northeast-2 = string
      me-south-1     = string
      ap-northeast-1 = string
      ca-central-1   = string
      sa-east-1      = string
      ap-east-1      = string
      ap-southeast-1 = string
      ap-southeast-2 = string
      eu-central-1   = string
      ap-southeast-3 = string
      us-east-1      = string
      us-east-2      = string
      us-west-1      = string
      us-west-2      = string
    })
    voltstack_gateway = object({
      af-south-1     = string
      ap-south-1     = string
      eu-north-1     = string
      eu-west-3      = string
      eu-south-1     = string
      eu-west-2      = string
      eu-west-1      = string
      ap-northeast-3 = string
      ap-northeast-2 = string
      me-south-1     = string
      ap-northeast-1 = string
      ca-central-1   = string
      sa-east-1      = string
      ap-east-1      = string
      ap-southeast-1 = string
      ap-southeast-2 = string
      eu-central-1   = string
      ap-southeast-3 = string
      us-east-1      = string
      us-east-2      = string
      us-west-1      = string
      us-west-2      = string
    })
  })
  default = {
    ingress_gateway = {
      af-south-1     = "ami-08744facfd887f92d"
      ap-south-1     = "ami-0bda3dcea89c5d041"
      eu-north-1     = "ami-0a825dd646f3ca83c"
      eu-west-3      = "ami-00a508f3ae0166adb"
      eu-south-1     = "ami-0a39703c6fcba60c9"
      eu-west-2      = "ami-07f1671a8acf956af"
      eu-west-1      = "ami-04beae0f9774b8f48"
      ap-northeast-3 = "ami-0e549fd46bc34dad9"
      ap-northeast-2 = "ami-0dba413f1ae8fed6d"
      me-south-1     = "ami-0dc2ff44f3c6e6f88"
      ap-northeast-1 = "ami-024976a3c31f41cd2"
      ca-central-1   = "ami-0c193c43523268e72"
      sa-east-1      = "ami-030b6602f95c6b41d"
      ap-east-1      = "ami-0f42f00a2a7ccf1b7"
      ap-southeast-1 = "ami-0d8589350ad5b70c7"
      ap-southeast-2 = "ami-069178fb7d4e94257"
      eu-central-1   = "ami-0156dae589b1bd776"
      ap-southeast-3 = "ami-0296f8254cf4fc461"
      us-east-1      = "ami-0aaed44d894a16abd"
      us-east-2      = "ami-072ac5ad86b390ac1"
      us-west-1      = "ami-09e2c941fc144cc64"
      us-west-2      = "ami-0a4218dd27123de5e"
    }
    ingress_egress_gateway = {
      af-south-1     = "ami-023e087f318476ed9"
      ap-south-1     = "ami-024041694fcfbe2dd"
      eu-north-1     = "ami-0345463aff25b88dc"
      eu-west-3      = "ami-0b8c7cdeff7eafcf2"
      eu-south-1     = "ami-0deb487fde00d53c2"
      eu-west-2      = "ami-01277d39e5e4fd47b"
      eu-west-1      = "ami-0c0403f654ab29c83"
      ap-northeast-3 = "ami-0ab73daa18a7bd36e"
      ap-northeast-2 = "ami-0e9545c604fb95caa"
      me-south-1     = "ami-04ee61928cc1d3678"
      ap-northeast-1 = "ami-0fcea17bd7b580959"
      ca-central-1   = "ami-09c004db075caf4ab"
      sa-east-1      = "ami-02f069fe09fae8d76"
      ap-east-1      = "ami-048436483e2554841"
      ap-southeast-1 = "ami-039d3da469422cad1"
      ap-southeast-2 = "ami-044595dc80554906d"
      eu-central-1   = "ami-04720f54d40337fe2"
      ap-southeast-3 = "ami-0e3f3f1ab4b3240e5"
      us-east-1      = "ami-02af1acad1eef7940"
      us-east-2      = "ami-029d17ae8507c9b4a"
      us-west-1      = "ami-0b91438f4f4bc1af9"
      us-west-2      = "ami-0d36a75587461b250"
    }
    voltstack_gateway = {
      af-south-1     = "ami-037b1a1d5ccfe3610"
      ap-south-1     = "ami-08a53309ab95573d6"
      eu-north-1     = "ami-05850a833a8205afc"
      eu-west-3      = "ami-04c05f1e003c8a5b4"
      eu-south-1     = "ami-0155b585d94aa8a47"
      eu-west-2      = "ami-0655eac30ba4816ae"
      eu-west-1      = "ami-04fa0945c604d4106"
      ap-northeast-3 = "ami-0199149abed7da517"
      ap-northeast-2 = "ami-09bc0eeba6d90514f"
      me-south-1     = "ami-0941ccabf475035be"
      ap-northeast-1 = "ami-0769202844d44c96b"
      ca-central-1   = "ami-0a4d8c8bc8ca1ab21"
      sa-east-1      = "ami-034b2b063f5bdeeb9"
      ap-east-1      = "ami-05cf4b6e9edb21588"
      ap-southeast-1 = "ami-03be5dbe1fa59a641"
      ap-southeast-2 = "ami-013b0ea6c71800c51"
      eu-central-1   = "ami-07860a3b1ab83ce62"
      ap-southeast-3 = "ami-065d3a99d7a896c70"
      us-east-1      = "ami-0a2121d65c9a600ea"
      us-east-2      = "ami-08762c8bd258c3b30"
      us-west-1      = "ami-0cae9e09eecedfec3"
      us-west-2      = "ami-04b388d0bc88442db"
    }
  }
}

variable "f5xc_ce_instance_type" {
  type = string
}

variable "f5xc_cluster_latitude" {
  type = string
}

variable "f5xc_cluster_longitude" {
  type = string
}

variable "f5xc_ce_gateway_type" {
  type = string
}

variable "owner_tag" {
  type = string
}
