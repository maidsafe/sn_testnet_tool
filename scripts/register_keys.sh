#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)
DEFAULT_WORKING_DIR="."
WORKING_DIR="${GITHUB_ACTION_PATH:-$DEFAULT_WORKING_DIR}"

#  ensure ips are registered
echo "Registering node keys w/ system"
mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
while read -r ip; do
    ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
done < ${WORKING_DIR}/${TESTNET_CHANNEL}-ip-list
wait

echo "Keys registered"
