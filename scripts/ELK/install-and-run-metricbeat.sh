#!/bin/bash

# Add gpg keys and install Metricbeat
echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

# Write to source
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update and install metricbeat
echo "Installing Metricbeat"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install metricbeat > /dev/null 2>&1

# Remove default config
rm -rf /etc/metricbeat/metricbeat.yml

# Pull metricbeat config file from s3
metric_beat_url="https://sn-node.s3.eu-west-2.amazonaws.com/testnet_tool/metricbeat.yml"
wget ${metric_beat_url} -O metricbeat.yml

# Get hostname
name=$(hostname)

# Search and replace hostname in config
sed -e "s/<MACHINE-NAME>/${name}/g" metricbeat.yml > /etc/metricbeat/metricbeat.yml

# Cleanup residual config
rm metricbeat.yml

# Start the service
systemctl start metricbeat
systemctl enable metricbeat
