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

# echo "Mem usage in mbs for $TESTNET_CHANNEL nodes at ip:"
cat workspace/${TESTNET_CHANNEL}/ip-list | while read line; do
  ip=$(echo $line | awk '{print $2}')
  name=$(echo $line | awk '{print $1}')  # echo "$ip"
  mb=$(ssh root@${ip} 'process=$(pgrep safenode -n) && xargs pmap $process | awk "/total/ { b=int(\$2/1024); printf b};"' ) && echo "$name: ${mb}MB" &

done

# echo "Mem usage in mbs for $TESTNET_CHANNEL nodes at ip:"
cat workspace/${TESTNET_CHANNEL}/ip-list | while read line; do
  ip=$(echo $line | awk '{print $2}')
  name=$(echo $line | awk '{print $1}')
  # echo "$ip"
  pid=$(ssh root@${ip} 'pgrep safenode' ) && echo "$name: ${pid}" 

done

cleanup