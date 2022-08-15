#!/bin/bash

set -e
DEFAULT_WORKING_DIR="."
WORKING_DIR="${WORKING_DIR:-$DEFAULT_WORKING_DIR}"

testnet_channel=$(terraform workspace show)



function copy_ips_from_s3() {
    aws s3 cp \
        "s3://safe-testnet-tool/$testnet_channel-ip-list" \
        "$WORKING_DIR/$testnet_channel-ip-list"
    aws s3 cp \
        "s3://safe-testnet-tool/$testnet_channel-genesis-ip" \
        "$WORKING_DIR/$testnet_channel-genesis-ip"
    aws s3 cp \
        "s3://safe-testnet-tool/$testnet_channel-network-contacts" \
        "$WORKING_DIR/$testnet_channel-network-contacts"
}


copy_ips_from_s3
./scripts/register_keys.sh
