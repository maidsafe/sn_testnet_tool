#!/bin/bash

set -e

SAFENODE_URL_PREFIX="https://sn-node.s3.eu-west-2.amazonaws.com"

SSH_KEY_PATH=${1}
NODE_COUNT=${2:-1}
NODE_BIN_PATH=${3}
NODE_VERSION=${4}
AUTO_APPROVE=${5}
OTLP_COLLECTOR_ENDPOINT=${6:-"http://dev-testnet-infra-543e2a753f964a15.elb.eu-west-2.amazonaws.com:4317"}
SKIP_UPLOAD=${7:-false}


 if [[ -n "$NODES_PER_MACHINE" ]]; then
    nodes_per_droplet=$NODES_PER_MACHINE
  else
    nodes_per_droplet=20
  fi

NODES_PER_MACHINE=$nodes_per_droplet
  
testnet_channel=$(terraform workspace show)
ip_list_file=workspace/${testnet_channel}/ip-list

function check_dependencies() {
  set +e
  declare -a dependecies=("terraform" "aws" "tar" "jq")
  for dependency in "${dependecies[@]}"
  do
    if ! command -v "$dependency" &> /dev/null; then
      echo "$dependency could not be found and is required"
      exit 1
    fi
  done
  set -e

  if [[ -z "${DO_PAT}" ]]; then
    echo "The DO_PAT env variable must be set with your personal access token."
    exit 1
  fi
  if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
    echo "The AWS_ACCESS_KEY_ID env variable must be set with your access key ID."
    exit 1
  fi
  if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
    echo "The AWS_SECRET_ACCESS_KEY env variable must be set with your secret access key."
    exit 1
  fi
  if [[ -z "${AWS_DEFAULT_REGION}" ]]; then
    echo "The AWS_DEFAULT_REGION env variable must be set. Default is usually eu-west-2."
    exit 1
  fi
  if [[ ! -z "${NODE_VERSION}" && ! -z "${NODE_BIN_PATH}" ]]; then
    echo "Both NODE_VERSION and NODE_BIN_PATH cannot be set at the same time."
    echo "Please use one or the other."
    exit 1
  fi

  # setup a file used in startup
  mkdir -p workspace/${testnet_channel}
  touch workspace/${testnet_channel}/node-1 || true
}

function run_terraform_apply() {
  local node_url="${SAFENODE_URL_PREFIX}/safenode-latest-x86_64-unknown-linux-musl.tar.gz"
  if [[ ! -z "${NODE_VERSION}" ]]; then
    node_url="${SAFENODE_URL_PREFIX}/safenode-${NODE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  elif [[ ! -z "${NODE_BIN_PATH}" ]]; then
    if [[ -d "${NODE_BIN_PATH}" ]]; then
      echo "The node bin path must be a file"
      exit 1
    fi
    local path=$(dirname "${NODE_BIN_PATH}")
  elif [[ -f "./workspace/${testnet_channel}/safenode" ]]; then
    local path=$(dirname "./workspace/${testnet_channel}/safenode")
  fi

  if [[ ! -z "${path}" ]]; then
    echo "Using node from $path"
    # The term 'custom' is used here rather than 'musl' because a locally built binary may not
    # be a musl build.
    archive_name="safenode-${testnet_channel}-x86_64-unknown-linux-custom.tar.gz"
    archive_path="/tmp/$archive_name"
    node_url="${SAFENODE_URL_PREFIX}/$archive_name"

    # if test -f "$ip_list_file"; then
    #     echo "Using preexisting bin from AWS for $testnet_channel."
    # else 
    #   if [[ "$SKIP_UPLOAD" != "true" ]]; then
    #     # echo "Creating $archive_path..."
    #     # tar -C $path -zcvf $archive_path safenode
    #     # echo "Uploading $archive_path to S3..."
    #     # aws s3 cp $archive_path s3://sn-node --acl public-read
    #   else 
    #     echo "Skipping upload of $archive_path to S3..."
    #   fi
    # fi
  fi

  terraform apply \
    -var "do_token=${DO_PAT}" \
    -var "pvt_key=${SSH_KEY_PATH}" \
    -var "number_of_droplets=${DROPLET_COUNT}" \
    -var "number_of_nodes_per_machine=${NODES_PER_MACHINE}" \
    # -var "node_url=${node_url}" \
    -var "otlp_collector_endpoint=${OTLP_COLLECTOR_ENDPOINT}" \
    --parallelism 15 ${AUTO_APPROVE}
}

function copy_ips_to_s3() {
  # This is only really used for debugging the nightly run.
  aws s3 cp \
    "./workspace/$testnet_channel/ip-list" \
    "s3://sn-node/testnet_tool/$testnet_channel-ip-list" \
    --acl public-read
}

# function pull_genesis_dbc_and_copy_to_s3() {
#   local genesis_dbc_path="./workspace/$testnet_channel/genesis-dbc"
#   echo "Pulling Genesis DBC from Genesis node"
#   rsync root@"$genesis_ip":~/node_data/genesis_dbc "$genesis_dbc_path"
#   aws s3 cp \
#     "$genesis_dbc_path" \
#     "s3://sn-node/testnet_tool/$testnet_channel/genesis-dbc" \
#     --acl public-read
# }

# function pull_genesis_key_and_copy_to_s3() {
#   local genesis_key_path="./workspace/$testnet_channel/genesis-key"
#   echo "Pulling Genesis key from Genesis node"
#   rsync root@"$genesis_ip":~/genesis-key "$genesis_key_path"
#   aws s3 cp \
#     "$genesis_key_path" \
#     "s3://sn-node/testnet_tool/$testnet_channel-genesis-key" \
#     --acl public-read
# }

# function kick_off_client() {
#   echo "Kicking off client tests..."
#   ip=$(cat workspace/${testnet_channel}/client-ip)
#   echo "Safe cli version is:"
#   ssh root@${ip} 'safe -V'

#   if test -f "$ip_list_file"; then
#       echo "Client data has already been put onto $testnet_channel."
#   else 
#     ssh root@${ip} 'safe files put loop_client_tests.sh'
#     # ssh root@${ip} 'bash -ic "nohup ./loop_client_tests.sh &; bash"'
#     # echo "Client tests should now be building/looping"
#     ssh root@${ip} 'time safe files put -r test-data'
#     echo "Test data should now exist"
#     echo "data exists" > workspace/${testnet_channel}/client-data-exists
#   fi

# }


function calculate_droplet_count() {
  DROPLET_COUNT=$(((NODE_COUNT / NODES_PER_MACHINE) + 1))

  
  if [[ $DROPLET_COUNT -lt 2 ]]; then
    DROPLET_COUNT=2
  fi
  
  echo "Running $DROPLET_COUNT droplets to get $NODE_COUNT nodes"
  echo "min count of nodes per machine is 20, unless you set NODES_PER_MACHINE env var, which is currently $NODES_PER_MACHINE"
  echo "(node-1 always runs on its own droplet)" # this is just for simplicity when setting up other nodes
}



check_dependencies
calculate_droplet_count
run_terraform_apply
copy_ips_to_s3
# pull_network_contacts_and_copy_to_s3
# pull_genesis_dbc_and_copy_to_s3
# pull_genesis_key_and_copy_to_s3
# kick_off_client


ssh root@$(cat workspace/$testnet_channel/node1-client ) 'unzip the-test-data.zip' -o

# ./scripts/upload-test-data.sh
# ./scripts/download-test-data.sh


# trigger dls in the background