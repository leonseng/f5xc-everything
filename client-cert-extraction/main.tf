resource "random_id" "id" {
  byte_length = 2
}

locals {
  project_name = "${var.project_name}-${random_id.id.dec}"
}

resource "volterra_namespace" "this" {
  name = local.project_name
}

resource "tls_private_key" "client" {
  algorithm = "RSA"
}

resource "local_file" "client_key" {
  content  = tls_private_key.client.private_key_pem
  filename = "${path.module}/tmp/${local.project_name}.client.key"
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name  = "${local.project_name}.client.example.com"
    organization = "F5"
  }
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem      = tls_cert_request.client.cert_request_pem
  ca_cert_pem           = file(var.ca_cert_file)
  ca_private_key_pem    = file(var.ca_key_file)
  validity_period_hours = 7200 # 300 days

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

resource "local_file" "client_cert" {
  content  = tls_locally_signed_cert.client.cert_pem
  filename = "${path.module}/tmp/${local.project_name}.client.pem"
}
