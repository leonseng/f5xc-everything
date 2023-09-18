provider "volterra" {
  api_p12_file = var.xc_api_p12_file
  url          = var.xc_api_endpoint
}

resource "volterra_cloud_credentials" "aws" {
  name      = "${local.name_prefix}-aws-cc"
  namespace = "system"

  aws_secret_key {
    access_key = var.xc_aws_access_key
    secret_key {
      clear_secret_info {
        url = "string:///${base64encode(var.xc_aws_secret_key)}"
      }
    }
  }
}
