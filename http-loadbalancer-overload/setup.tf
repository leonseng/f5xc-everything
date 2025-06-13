resource "random_id" "id" {
  byte_length = 2
  prefix      = "${var.project_name}-"
}

locals {
  name_prefix = random_id.id.dec
}

resource "volterra_healthcheck" "basic" {
  name      = local.name_prefix
  namespace = var.f5xc_namespace

  http_health_check {
    use_http2              = false
    use_origin_server_name = true
    path                   = "/get"
    expected_status_codes  = ["200-399"]
  }

  healthy_threshold   = 2
  interval            = 10
  timeout             = 1
  unhealthy_threshold = 5
}

resource "volterra_origin_pool" "httpbin" {
  depends_on = [
    volterra_healthcheck.basic
  ]

  name                   = local.name_prefix
  namespace              = var.f5xc_namespace
  port                   = 443
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  use_tls {
    default_session_key_caching = true
    use_host_header_as_sni      = true
    skip_server_verification    = true
    no_mtls                     = true
    tls_config {
      low_security = true
    }
  }

  healthcheck {
    tenant    = var.f5xc_tenant_id
    namespace = var.f5xc_namespace
    name      = volterra_healthcheck.basic.name
  }

  origin_servers {
    public_name {
      dns_name = "httpbin.org"
    }
  }
}

resource "tls_private_key" "example" {
  count = var.origin_count

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  count = var.origin_count

  private_key_pem       = tls_private_key.example[count.index].private_key_pem
  validity_period_hours = 4380
  early_renewal_hours   = 3

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["httpbin-${count.index}.example.com"]

  subject {
    common_name  = "httpbin-${count.index}.example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "volterra_certificate" "example" {
  count = var.origin_count

  name            = "${local.name_prefix}-httpbin-${count.index}"
  namespace       = var.f5xc_namespace
  certificate_url = "string:///${base64encode(tls_self_signed_cert.example[count.index].cert_pem)}"

  private_key {
    clear_secret_info {
      url = "string:///${base64encode(tls_private_key.example[count.index].private_key_pem)}"
    }
  }
}
