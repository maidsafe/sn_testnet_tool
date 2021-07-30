#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

#  ensure ips are registered
echo "Registering node keys w/ system"
while read -r ip; do
    ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
done < ${TESTNET_CHANNEL}-ip-list
wait

echo "Keys registered"
