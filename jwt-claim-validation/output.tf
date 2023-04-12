output "namespace" {
  value = local.project_name
}

output "proxy_fqdn" {
  value = "${local.project_name}.example.com"
}

output "proxy_ip" {
  value = data.volterra_http_loadbalancer_state.proxy.ip_address
}
