#!/bin/bash


repo_owner="$1"
if [[ -z "$repo_owner" ]]; then
  echo "A repo owner must be passed to initialise the node."
  exit 1
fi

commit_hash="$2"
if [[ -z "$commit_hash" ]]; then
  echo "A commit hash must be passed to initialise the node."
  exit 1
fi

function setup_build_tools() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -q --default-host x86_64-unknown-linux-gnu --default-toolchain stable --profile minimal -y
# avoid modals for kernel upgrades hanging setup
  sudo DEBIAN_FRONTEND=noninteractive apt update
  build_tools_installed="true"
  retry_count=1
  while [[ $retry_count -le 20 ]]; do
    echo "Attempting to install build tools..."
    sudo DEBIAN_FRONTEND=noninteractive apt install build-essential ripgrep -y -qq
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "build tools installed successfully"
        build_tools_installed="true"
        break
    fi
    echo "Failed to install build tools."
    echo "Attempted $retry_count times. Will retry up to 20 times. Sleeping for 10 seconds."
    ((retry_count++))
    sleep 10
    # Without running this again there are times when it will just fail on every retry.
    sudo DEBIAN_FRONTEND=noninteractive apt update
  done
  if [[ "$build_tools_installed" == "false" ]]; then
    echo "Failed to install build tools."
    exit 1
  fi
}

function init_node_dirs() {
  chmod +x ./loop_client_tests.sh
  chmod +x ./dl_files.sh
  mkdir -p ~/node_data
  mkdir -p ~/.safe/node
  mkdir -p ~/tests
  mkdir -p ~/.safe/network_contacts
  mkdir -p ~/logs
  mv index tests/index
}

function setup_network_contacts() {
  cp ~/network_contacts ~/.safe/network_contacts/network_contacts
  ln -s ~/.safe/network_contacts/network_contacts ~/.safe/network_contacts/default
}

function build_client_tests() {
  (
    git clone https://github.com/${repo_owner}/safe_network -q
    cd safe_network
    git checkout ${commit_hash}
  )
  export RUST_LOG=sn_client=trace
  client_test_cmd=$(printf '%s' \
    "cd safe_network/sn_client && " \
    "source $HOME/.cargo/env && " \
    "cargo test --release --no-run" \
  )

  nohup bash -c "$client_test_cmd" &
  
  sleep 5 # For some reason this is necessary for the persistence of the process launched by nohup.
}


function put_test_data() {

  export RUST_LOG=sn_client,sn_cli
  
  put_data_cmd=$(printf '%s' \
    "safe -V && " \
    "safe files put -r test-data" \
  )
  
  nohup bash -c "$put_data_cmd" &
  
  sleep 5 # For some reason this is necessary for the persistence of the process launched by nohup.
}

setup_build_tools
init_node_dirs
setup_network_contacts
build_client_tests
put_test_data
