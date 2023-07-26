#!/bin/bash

TESTNET_CHANNEL=$(terraform workspace show)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

mkdir -p workspace/${TESTNET_CHANNEL}/droplets
export TESTNET_CHANNEL

process_logs() {
  name=$1
  ip=$2
  if [[ -z $name || -z $ip ]]; then
    echo "$name $ip - Skipping line due to empty name or IP"
  else
    # echo "Getting $name nohup file from $ip"
    rsync -arz root@${ip}:~/nohup.out workspace/${TESTNET_CHANNEL}/droplets/${name}__${ip} 
    if grep -q "Killed" "workspace/${TESTNET_CHANNEL}/droplets/${name}__${ip}/nohup.out"; then
      ssh root@${ip} 'dmesg | rg "Killed"' > "workspace/${TESTNET_CHANNEL}/droplets/${name}__${ip}/killed.log"
    fi
  fi
}

export -f process_logs

parallel --timeout 30 -a workspace/${TESTNET_CHANNEL}/ip-list --colsep ' ' --jobs 10 process_logs '{1}' '{2}'

echo "Nohup files updated"


# Concatenate and display killed.log files
./scripts/show-broken-nodes.sh

