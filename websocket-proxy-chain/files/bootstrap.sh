#!/usr/bin/env bash
set -e

echo ">>> Begin bootstrap"
cd /home/ubuntu/
cp /tmp/nginx.conf nginx.conf
cp /tmp/docker-compose.yaml docker-compose.yaml
chown ubuntu:ubuntu nginx.conf
chown ubuntu:ubuntu docker-compose.yaml

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

echo ">>> Starting services using Docker compose"
docker compose up -d

echo ">>> Bootstrap completed"
