#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

echo ""
echo "> Grabbing latest network contacts from $(terraform workspace show) genesis node"
echo ""

scp root@$(cat workspace/$(terraform workspace show)/genesis-ip):~/node_data/section_tree workspace/$(terraform workspace show)/network-contacts
echo "workspace/$(terraform workspace show)/network-contacts has been updated"
