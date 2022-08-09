#!/bin/bash

# Add gpg keys and install ElasticSearch
echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "Installing required libs"
sudo apt-get install apt-transport-https -y > /dev/null 2>&1

# Write to source
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install ElasticSearch
echo "Installing ElasticSearch"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install elasticsearch -y > /dev/null 2>&1

# Write customised config over default config
echo "Pull config from S3"
wget https://raw.githubusercontent.com/maidsafe/sn_testnet_tool/main/scripts/ELK/templates/elasticsearch.yml -O /etc/elasticsearch/elasticsearch.yml

# Get public IP
echo "Fetching Public IP"
ip=$(curl ident.me)

# Replace the IP placeholder with host's public IP
echo "Replacing placeholder with Public IP"
sed -i "s/<ELASTIC-MACHINE-PUBLIC-IP>/${ip}/g" /etc/elasticsearch/elasticsearch.yml

# Start the service
echo "Starting ElasticSearch service"
systemctl start elasticsearch