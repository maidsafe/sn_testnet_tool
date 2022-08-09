#!/bin/bash

ELASTIC=${1}

# Add gpg keys and install Kibana
echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "Installing required libs"
sudo apt-get install apt-transport-https -y > /dev/null 2>&1

# Write to source
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install Kibana
echo "Installing kibana"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install kibana -y > /dev/null 2>&1

# Write customised config over default config
echo "Pull config from S3"
wget https://raw.githubusercontent.com/maidsafe/sn_testnet_tool/main/scripts/ELK/templates/kibana.yml -O kibana.yml

# Get public IP
echo "Fetching Public IP"
ip=$(curl ident.me)

# Replace the IP placeholder with host's public IP
echo "Replacing placeholders with Public IPs of Elastic"
sed -e "s/<ELASTIC-MACHINE-PUBLIC-IP>/${ELASTIC}/g" -e "s/<KIBANA-MACHINE-PUBLIC-IP>/${ip}/g" kibana.yml > /etc/kibana/kibana.yml

# Cleanup residual config
rm kibana.yml

# Start the service
systemctl start kibana