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

echo "Client node tests info: $TESTNET_CHANNEL:"
stats=$(ssh root@$(cat workspace/${TESTNET_CHANNEL}/client-ip) 'rg " passed;" *.log --stats' ) && echo "${stats}" &

cleanup