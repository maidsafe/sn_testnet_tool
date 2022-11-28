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

echo "Running client tests from ${TESTNET_CHANNEL} client node"
ssh root@$(cat ${TESTNET_CHANNEL}-client-ip) 'nohup ./loloop_client_tests.sh'

cleanup