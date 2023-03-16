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

rm -rf workspace/${TESTNET_CHANNEL}/pids
mkdir -p workspace/${TESTNET_CHANNEL}/pids

rg  "Membership \- d.+ L" workspace/$(terraform workspace show)/logs -u | sort > voted-off.log 

# echo "pid for $TESTNET_CHANNEL nodes at ip:"
cat workspace/${TESTNET_CHANNEL}/ip-list | while read line; do
  ip=$(echo $line | awk '{print $2}')
  name=$(echo $line | awk '{print $1}')  # echo "$ip"
  rg $ip voted-off.log
done

cleanup