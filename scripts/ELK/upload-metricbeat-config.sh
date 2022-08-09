#!/bin/bash

ELASTIC=${1}
KIBANA=${2}

wget https://raw.githubusercontent.com/maidsafe/sn_testnet_tool/main/scripts/ELK/templates/metricbeat.yml -O metricbeat.yml

sed -i "s/<ELASTIC-MACHINE-PUBLIC-IP>/${ELASTIC}/g" metricbeat.yml
sed -i "s/<KIBANA-MACHINE-PUBLIC-IP>/${KIBANA}/g" metricbeat.yml

aws s3 cp metricbeat.yml s3://safe-testnet-tool/metricbeat.yml --acl public-read