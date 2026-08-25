output "name_prefix" {
  value = local.name_prefix
}

output "origin_pool_name" {
  value = volterra_origin_pool.httpbin.name
}
