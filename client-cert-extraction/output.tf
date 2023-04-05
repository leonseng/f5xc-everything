output "client_key_file" {
  value = "${path.module}/tmp/${local.project_name}.client.key"
}

output "client_cert_file" {
  value = "${path.module}/tmp/${local.project_name}.client.pem"
}

output "namespace" {
  value = local.project_name
}

output "proxy_fqdn" {
  value = "${local.project_name}.example.com"
}
