#!/bin/bash

echo "Installing Docker"
curl -SSL https://get.docker.com/ | sh
systemctl start docker
systemctl enable docker

echo "Checking Docker Compose version"
docker-compose --version

echo "Installing Docker Compose"
curl -L "https://github.com/docker/compose/releases/download/1.28.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker>
chmod +x /usr/local/bin/docker-compose
sudo In -s /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Setting vm.max_map_count"
sed -t 's/^#*\(vm.max_map_count\s*=\s*\).*/\1_262144/' /etc/sysctl.conf

echo "Cloning Wazuh Docker repository"
git clone https://github.com/wazuh/wazuh-docker.git -b v4.2.6 --depth=1

# Check if already in the desired directory
if [[ "$(basename "$(pwd)")" != "wazuh-docker" ]]; then
	echo "Changing to wazuh-docker directory..."
	cd wazuh-docker || exit 1
fi

echo "Generating OpenDistro certificates"
docker-compose -f generate-opendistro-certs.yml run--rm generator
echo "Generating Kibana and Nginx self-signed certificates"
bash production_cluster/kibana_ssl/generate-self-signed-cert.sh
bash production_cluster/nginx/ssl/generate-self-signed-cert.sh

echo "Starting the Wazuh production cluster"
docker-compose -f production-cluster.yml up -d

