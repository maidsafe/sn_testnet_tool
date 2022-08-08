#!/bin/bash

ELASTIC-IP=${1}

# Add gpg keys and install Kibana
echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "Installing required libs"
sudo apt-get install apt-transport-https && sudo apt-get install rpl

# Write to source
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install Kibana
echo "Installing kibana"
sudo apt-get update && sudo apt-get install kibana

# Write customised config over default config
echo "Pull config from S3"
wget https://safe-testnet-tool.s3.eu-west-2.amazonaws.com/ELK/templates/kibana.yml -O /etc/kibana/kibana.yml

# Get public IP
echo "Fetching Public IP"
ip=$(curl ident.me)

# Replace the IP placeholder with host's public IP
echo "Replacing placeholders with Public IPs of Elastic"
rpl "<ELASTIC-MACHINE-PUBLIC-IP>" "${ELASTIC-IP}" /etc/kibana/kibana.yml
rpl "<KIBANA-MACHINE-PUBLIC-IP>" "${ip}" /etc/kibana/kibana.yml

# Start the service
systemctl start kibana