output "namespace" {
  value = local.project_name
}

output "proxy_fqdn" {
  value = "${local.project_name}.example.com"
}
