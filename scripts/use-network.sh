#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

echo ""
echo "> Cleaning up p2p cache and replacing prefix map"
echo ""
rm -rf ~/.safe/qp2p || true
rm -rf "$HOME/.safe/network_contacts/${TESTNET_CHANNEL}" || true
mkdir -p ~/.safe/network_contacts
cp "${TESTNET_CHANNEL}-network-contacts" "$HOME/.safe/network_contacts/default"


echo "You are now ready to use the $TESTNET_CHANNEL network"
