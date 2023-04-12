resource "random_id" "id" {
  byte_length = 2
}

locals {
  project_name = "${var.project_name}-${random_id.id.dec}"
}

resource "volterra_namespace" "this" {
  name = local.project_name
}
