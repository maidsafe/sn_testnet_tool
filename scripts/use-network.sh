#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

echo ""
echo "> Cleaning up p2p cache and replacing node conn info"
echo ""
rm -rf ~/.safe/qp2p
rm -rf ~/.safe/node/node_connection_info.config
cp ${TESTNET_CHANNEL}-node_connection_info.config ~/.safe/node/node_connection_info.config


echo "You are now ready to use the $TESTNET_CHANNEL network"