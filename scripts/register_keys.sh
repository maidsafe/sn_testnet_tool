#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)
DEFAULT_WORKING_DIR="."
WORKING_DIR="${WORKING_DIR:-$DEFAULT_WORKING_DIR}"

#  ensure ips are registered
echo "Registering node keys w/ system"
mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
for ip in $(cat ${TESTNET_CHANNEL}-ip-list | awk '{print $2}'); do
    ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
done
wait

echo "Keys registered"
