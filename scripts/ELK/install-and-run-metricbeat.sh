#!/bin/bash

function install_metricbeat() {
  sudo DEBIAN_FRONTEND=noninteractive apt update > /dev/null 2>&1
  retry_count=1
  metricbeat_installed="false"
  while [[ $retry_count -le 20 ]]; do
    echo "Attempting to install metricbeat..."
    sudo DEBIAN_FRONTEND=noninteractive apt install metricbeat -y > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "metricbeat installed successfully"
        metricbeat_installed="true"
        break
    fi
    echo "Failed to install metricbeat."
    echo "Attempted $retry_count times. Will retry up to 20 times. Sleeping for 10 seconds."
    ((retry_count++))
    sleep 10
    # Without running this again there are times when it will just fail on every retry.
    sudo DEBIAN_FRONTEND=noninteractive apt update > /dev/null 2>&1
  done
  if [[ "$metricbeat_installed" == "false" ]]; then
    echo "Failed to install metricbeat"
    exit 1
  fi
}

echo "Setting up gpg keys"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

install_metricbeat

rm -rf /etc/metricbeat/metricbeat.yml

metric_beat_url="https://sn-node.s3.eu-west-2.amazonaws.com/testnet_tool/metricbeat.yml"
wget ${metric_beat_url} -O metricbeat.yml

sed -e "s/<MACHINE-NAME>/$(hostname)/g" metricbeat.yml > /etc/metricbeat/metricbeat.yml

rm metricbeat.yml

# small wait to avoid missing file errors starting up
sleep 5

systemctl start metricbeat
systemctl enable metricbeat
