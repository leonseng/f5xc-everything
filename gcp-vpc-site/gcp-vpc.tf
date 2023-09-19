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

output "gcp_inside_vpc_id" {
  value = google_compute_network.inside.id
}

output "gcp_inside_subnet" {
  value = google_compute_subnetwork.inside.id
}

output "gcp_outside_vpc_id" {
  value = google_compute_network.outside.id
}

output "gcp_outside_subnet" {
  value = google_compute_subnetwork.outside.id
}
