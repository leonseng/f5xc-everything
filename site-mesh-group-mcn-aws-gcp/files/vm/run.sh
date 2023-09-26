#!/usr/bin/env bash

set -e

echo ">>> Waiting for Internet access"
while true
do
  if curl -m 3 -s icanhazip.com >/dev/null; then
    break
  else
    echo "Internet is not available, waiting for 5 seconds..."
    sleep 5
  fi
done

echo ">>> Installing Docker"
apt-get update
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker ubuntu

echo ">>> Starting services"
docker network create custom
docker run --restart=always -d --name httpbin --network custom kennethreitz/httpbin

echo "Home is $HOME"
export CAROOT="/root"
docker run --restart=always -d --name nginx -p 80:80 --network custom \
  -v /bootstrap/nginx/nginx.conf:/etc/nginx/nginx.conf \
  nginx
