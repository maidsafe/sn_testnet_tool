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

# bytehound

# sudo apt-get install yarn
# wget https://github.com/koute/bytehound/releases/download/0.8.0/bytehound-x86_64-unknown-linux-gnu.tgz
# tar -xf bytehound-x86_64-unknown-linux-gnu.tgz

# $ export MEMORY_PROFILER_LOG=warn
# $ LD_PRELOAD=./libbytehound.so ./your_application
# $ ./bytehound server memory-profiling_*.dat