terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~> 0.11"
    }
  }
}

locals {
  f5xc_tenant_name = join("-",
    slice(
      split("-", var.f5xc_tenant_id),
      0,
      length(split("-", var.f5xc_tenant_id)) - 1
    )
  )
}

provider "volterra" {
  api_p12_file = var.f5xc_api_p12_file
  url          = "https://${local.f5xc_tenant_name}.console.ves.volterra.io/api"
}

provider "tls" {}
