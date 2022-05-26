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


# echo "pid for $TESTNET_CHANNEL nodes at ip:"
for ip in $(<${TESTNET_CHANNEL}-ip-list xargs); do
  # echo "$ip"
    pid=$(ssh root@${ip} 'pgrep sn_node' ) && echo "$ip: ${pid}" &

done

cleanup