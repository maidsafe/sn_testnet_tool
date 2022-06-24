#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

echo ""
echo "> Cleaning up p2p cache and replacing prefix map"
echo ""
rm -rf ~/.safe/qp2p || true
rm -rf "$HOME/.safe/prefix_maps/${TESTNET_CHANNEL}" || true
mkdir -p ~/.safe/prefix_maps
cp "${TESTNET_CHANNEL}-prefix-map" "$HOME/.safe/prefix_maps/${TESTNET_CHANNEL}-prefix-map"
ln -s "$HOME/.safe/prefix_maps/${TESTNET_CHANNEL}-prefix-map" "$HOME/.safe/prefix_maps/${TESTNET_CHANNEL}"

echo "You are now ready to use the $TESTNET_CHANNEL network"