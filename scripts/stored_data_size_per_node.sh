#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

echo "Storage space usage per nodes for $TESTNET_CHANNEL:"
cat workspace/${TESTNET_CHANNEL}/ip-list | while read line; do
  ip=$(echo $line | awk '{print $2}')
  name=$(echo $line | awk '{print $1}')
  size=$(ssh root@${ip} 'du -sch node_data | tail -1' ) && echo "$name: ${size}" &
done

cleanup