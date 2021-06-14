#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

echo ""
echo "> Cleaning up p2p cache and replacing node conn info"
echo ""
rm -rf ~/.safe/qp2p || true
rm -rf ~/.safe/node/node_connection_info.config || true
mkdir -p ~/.safe/node
cp ${TESTNET_CHANNEL}-node_connection_info.config ~/.safe/node/node_connection_info.config


echo "You are now ready to use the $TESTNET_CHANNEL network"