#!/bin/bash

# This is mainly intended to be used for debugging the nightly run.
# It's expecting the ip list file to be in the same directory the script is running from.

set -e

testnet_channel="$1"
if [[ -z "$testnet_channel" ]]; then
  echo "The name of the testnet must be provided"
  exit 1
fi

mkdir -p ~/.ssh/
touch ~/.ssh/known_hosts
mkdir -p logs/${testnet_channel}
cat ${testnet_channel}-ip-list | while read line; do
  name=$(echo $line | awk '{print $1}')
  ip=$(echo $line | awk '{print $2}')
  echo "Getting $name logs from $ip"
  rsync \
    --rsh="ssh -o StrictHostKeyChecking=no" \
    --verbose \
    --recursive \
    root@${ip}:~/logs logs/${testnet_channel}/${name}___${ip}
done
