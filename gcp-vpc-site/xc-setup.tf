provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_endpoint
}

resource "volterra_cloud_credentials" "gcp" {
  name      = "${local.name_prefix}-gcp-cc"
  namespace = "system"

  gcp_cred_file {
    credential_file {
      clear_secret_info {
        url = "string:///${google_service_account_key.this.private_key}"
      }
    }
  }
}
