#!/bin/bash

node_url="$1"
if [[ -z "$node_url" ]]; then
  echo "A URL for the node binary must be passed to initialise the node."
  exit 1
fi

# bind_ip_address="$3"
# if [[ -z "$bind_ip_address" ]]; then
#   echo "A bind ip address must be passed to initialise the node."
#   exit 1
# fi


port="$2"
if [[ -z "$port" ]]; then
  echo "A port must be passed to initialise the node."
  exit 1
fi


# log_level="$6"
# if [[ -z "$log_level" ]]; then
#   echo "A log level must be passed to initialise the node."
#   exit 1
# fi

node_name="$3"
if [[ -z "$node_name" ]]; then
  echo "The node name must be passed to initialize the node."
  exit 1
fi

node_ip_address="$4"
if [[ -z "$node_ip_address" ]]; then
  echo "A node ip address must be passed to initialise the node RPC."
  exit 1
fi

peers="$5"
if [[ -z "$peers" ]]; then
  echo "No peer supplied, this must be the first node"
fi

nodes_to_run_on_this_machine="$6"
if [[ -z "$nodes_to_run_on_this_machine" ]]; then
  echo "No nodes count supplied"
fi


# otlp_collector_endpoint="$8"
# if [[ -z "$otlp_collector_endpoint" ]]; then
#   echo "The OpenTelementry Collector endpoint must be provided to export the traces."
#   exit 1
# fi

function install_deps() {
  # This is the first package we attempt to install. There are issues with apt
  # when the machine is initially used. Sometimes it is still running in the
  # background, in which case there will be an error about a file being locked.
  # Other times, the heaptrack package won't be available because it seems to
  # be some kind of timing issue: if you run the install command too quickly
  # after the update command, apt will complain it can't find the package.
  sudo DEBIAN_FRONTEND=noninteractive apt update > /dev/null 2>&1
  retry_count=1
  deps_installed="false"
  while [[ $retry_count -le 20 ]]; do
    echo "Attempting to install heaptrack..."
    sudo DEBIAN_FRONTEND=noninteractive apt install ripgrep wget parallel unzip -y > /dev/null 2>&1
    # sudo DEBIAN_FRONTEND=noninteractive apt install ripgrep heaptrack wget parallel unzip -y > /dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -eq 0 ]]; then
        echo "deps installed successfully"
        deps_installed="true"
        break
    fi
    echo "Failed to install deps."
    echo "Attempted $retry_count times. Will retry up to 20 times. Sleeping for 3 seconds."
    ((retry_count++))
    sleep 3
    # Without running this again there are times when it will just fail on every retry.
    sudo DEBIAN_FRONTEND=noninteractive apt update > /dev/null 2>&1
  done
  if [[ "$deps_installed" == "false" ]]; then
    echo "Failed to install deps"
    exit 1
  fi
}

function install_node() {
  archive_name=$(awk -F '/' '{ print $4 }' <<< $node_url)
  wget ${node_url}
  tar xf $archive_name
  chmod +x safenode
  # mkdir -p ~/node_data
  # mkdir -p ~/.safe/node
}


function run_node() {
  export SN_LOG=sn_node=debug,safenode=debug,sn_logging=debug,sn_networking=debug
  # export SN_LOG=all
  export RUST_LOG_OTLP=safenode=debug
  # export OTLP_SERVICE_NAME="${node_name}"
  # export OTEL_EXPORTER_OTLP_ENDPOINT="${otlp_collector_endpoint}"
  # export TOKIO_CONSOLE_BIND="${bind_ip_address}:6669",
  i=${1:-1} 

  port=$((12000 + i))

  # peers exists and has length > 0
  if [[ -n "$peers" ]]; then
    echo "supplied peers var is $peers"

     node_cmd=$(printf '%s' \
      "./safenode " \
      "--peer $peers " \
      "--log-output-dest data-dir " \
      "--rpc " \
      "$node_ip_address:$port "
    )


  # Otherwise, we're genesis, and we'll start only one node
  else
    node_cmd=$(printf '%s' \
      "./safenode " \
      "--log-output-dest data-dir " \
      "--rpc " \
      "$node_ip_address:$port "
    )
  fi
  
  echo "Launching node with: $node_cmd"
  nohup sh -c "$node_cmd" &
  sleep 1
  
}

install_deps
install_node
# setup_network_contacts

# Check if the environment variable is set
if [[ -n "$nodes_to_run_on_this_machine" ]]; then
  nodes_to_run=$nodes_to_run_on_this_machine
else
  nodes_to_run=20
fi

if [[ -n "$peers" ]]; then

  for ((i=1; i <= nodes_to_run; i++))
  do
    run_node $i
  done

else
  run_node
fi