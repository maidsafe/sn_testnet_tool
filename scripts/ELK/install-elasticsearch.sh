#!/bin/bash

# Add gpg keys and install ElasticSearch
echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "Installing required libs"
sudo apt-get install apt-transport-https && sudo apt-get install rpl

# Write to source
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install ElasticSearch
echo "Installing ElasticSearch"
sudo apt-get update && sudo apt-get install elasticsearch

# Write customised config over default config
echo "Pull config from S3"
wget https://safe-testnet-tool.s3.eu-west-2.amazonaws.com/ELK/templates/elasticsearch.yml -O /etc/elasticsearch/elasticsearch.yml

# Get public IP
echo "Fetching Public IP"
ip=$(curl ident.me)

# Replace the IP placeholder with host's public IP
echo "Replacing placeholder with Public IP"
rpl "<ELASTIC-MACHINE-PUBLIC-IP>" "${ip}" /etc/elasticsearch/elasticsearch.yml

# Start the service
echo "Starting ElasticSearch service"
systemctl start elasticsearch