resource "google_compute_network" "inside" {
  name                    = "${local.name_prefix}-inside"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "inside" {
  name          = "${local.name_prefix}-inside"
  ip_cidr_range = cidrsubnet(var.gcp_inside_vpc_cidr, 8, 1)
  region        = var.gcp_region
  network       = google_compute_network.inside.name
}

resource "google_compute_network" "outside" {
  name                    = "${local.name_prefix}-outside"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "outside" {
  name          = "${local.name_prefix}-outside"
  ip_cidr_range = cidrsubnet(var.gcp_outside_vpc_cidr, 8, 1)
  region        = var.gcp_region
  network       = google_compute_network.outside.name
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

output "inside_vpc_id" {
  value = google_compute_network.inside.id
}

output "inside_subnets" {
  value = google_compute_subnetwork.inside.id
}

output "outside_vpc_id" {
  value = google_compute_network.outside.id
}

output "outside_subnets" {
  value = google_compute_subnetwork.outside.id
}
