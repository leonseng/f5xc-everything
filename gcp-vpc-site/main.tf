terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "~> 0.11"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

data "http" "gcp_iam_policy" {
  url = "https://gitlab.com/volterra.io/cloud-credential-templates/-/raw/master/gcp/f5xc_gcp_vpc_role.yaml"
}

resource "google_project_iam_custom_role" "this" {
  role_id     = replace(local.name_prefix, "-", "_")
  title       = local.name_prefix
  description = local.name_prefix
  permissions = yamldecode(data.http.gcp_iam_policy.response_body).includedPermissions
}

resource "google_service_account" "this" {
  account_id = local.name_prefix
}

resource "google_service_account_key" "this" {
  service_account_id = google_service_account.this.name
}

resource "google_project_iam_binding" "this" {
  project = var.gcp_project
  role    = google_project_iam_custom_role.this.name

  members = [
    "serviceAccount:${google_service_account.this.email}",
  ]
}

provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_endpoint
}

resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_name}-"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

locals {
  name_prefix = random_id.id.dec
  my_ip       = chomp(data.http.myip.response_body)
}
