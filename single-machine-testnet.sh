#!/bin/bash
# this is steps to use a droplet for an internal testnet should we want to...
# this has not yet been tested as a script... 
# killall sn_node
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# sudo apt-get update
# sudo apt install build-essential

# git clone https://github.com/maidsafe/safe_network.git
# cd safe_network 
# bash

# sudo apt-get install ripgrep
# killall sn_node ||true && rm -rf ~/.safe/qp2p || true && rm -rf ~/.safe/node/local-test-network || true && RUST_LOG=safe_network=trace cargo run --release --bin testnet --features=always-joinable,test-utils && ./resources/scripts/network_is_ready_cli.sh
