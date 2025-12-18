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
    private_name {
      outside_network = true
      dns_name        = "test.com"
      site_locator {
        site {
          name      = "lseng-proxmox"
          namespace = "system"
          tenant    = var.f5xc_tenant_id
        }
      }
    }
  }
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem       = tls_private_key.example.private_key_pem
  validity_period_hours = 4380
  early_renewal_hours   = 3

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["httpbin.example.com"]

  subject {
    common_name  = "httpbin.example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "volterra_certificate" "example" {
  name            = "${local.name_prefix}-httpbin"
  namespace       = var.f5xc_namespace
  certificate_url = "string:///${base64encode(tls_self_signed_cert.example.cert_pem)}"

  private_key {
    clear_secret_info {
      url = "string:///${base64encode(tls_private_key.example.private_key_pem)}"
    }
  }
}

resource "volterra_http_loadbalancer" "app" {
  depends_on = [
    volterra_origin_pool.httpbin,
    volterra_certificate.example
  ]

  name                             = local.name_prefix
  namespace                        = var.f5xc_namespace
  domains                          = ["httpbin.example.com"]
  advertise_on_public_default_vip  = true
  default_sensitive_data_policy    = true
  disable_api_definition           = true
  disable_api_discovery            = true
  disable_malicious_user_detection = true
  disable_malware_protection       = true
  disable_rate_limit               = true
  disable_threat_mesh              = true
  disable_trust_client_ip_headers  = true
  disable_api_testing              = true
  disable_waf                      = true
  no_challenge                     = true
  round_robin                      = true
  no_service_policies              = true
  user_id_client_ip                = true
  l7_ddos_protection {
    ddos_policy_none = true
    mitigation_block = true
  }

  https {
    enable_path_normalize = true
    http_redirect         = true
    port                  = 443
    tls_cert_params {
      no_mtls = true

      tls_config {
        default_security = true
      }

      certificates {
        tenant    = var.f5xc_tenant_id
        namespace = var.f5xc_namespace
        name      = "${local.name_prefix}-httpbin"
      }

    }
  }

  waf_exclusion {
    waf_exclusion_inline_rules {
      rules {
        metadata {
          name = "test"
        }
        any_path   = true
        any_domain = true
        app_firewall_detection_control {
          exclude_bot_name_contexts {
            bot_name = "Alamofire"
          }

          exclude_violation_contexts {
            context           = "CONTEXT_BODY"
            context_name      = ""
            exclude_violation = "VIOL_JSON_MALFORMED"
          }
        }
      }
    }
  }

  routes {
    simple_route {
      http_method = "ANY"

      path {
        prefix = "/"
      }

      auto_host_rewrite = true

      headers {
        name  = "host"
        exact = "httpbin.example.com"
      }

      origin_pools {
        pool {
          tenant    = var.f5xc_tenant_id
          namespace = var.f5xc_namespace
          name      = volterra_origin_pool.httpbin.name
        }
      }

      advanced_options {
        common_buffering          = true
        common_hash_policy        = true
        default_retry_policy      = true
        disable_mirroring         = true
        disable_prefix_rewrite    = true
        disable_spdy              = true
        disable_web_socket_config = true
        priority                  = "DEFAULT"
        retract_cluster           = true
        inherited_waf_exclusion   = true
      }
    }

  }
}
