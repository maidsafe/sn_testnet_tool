#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

#  ensure ips are registered
echo "Registering node keys w/ system"
while read -r ip
        do
            ssh-keyscan -H ${ip} >> ~/.ssh/known_hosts
        done < ip-list

echo "Keys registered"
