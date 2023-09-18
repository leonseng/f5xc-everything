#cloud-config

write_files:
- encoding: b64
  content: ${bootstrap_b64}
  path: /tmp/bootstrap.sh
  permissions: '0755'
- encoding: b64
  content: ${docker_compose_b64}
  path: /tmp/docker-compose.yaml
  permissions: '0644'
- encoding: b64
  content: ${nginx_conf_b64}
  path: /tmp/nginx.conf
  permissions: '0644'

runcmd:
- /tmp/bootstrap.sh
