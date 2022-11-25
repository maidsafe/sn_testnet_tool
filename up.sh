#!/bin/bash

set -e

SN_NODE_URL_PREFIX="https://sn-node.s3.eu-west-2.amazonaws.com"

SSH_KEY_PATH=${1}
NODE_COUNT=${2:-1}
NODE_BIN_PATH=${3}
NODE_VERSION=${4}
CLIENT_COUNT=${5}
AUTO_APPROVE=${6}

testnet_channel=$(terraform workspace show)

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
}

function run_terraform_apply() {
  local node_url="$SN_NODE_URL_PREFIX/sn_node-latest-x86_64-unknown-linux-musl.tar.gz"
  if [[ ! -z "${NODE_VERSION}" ]]; then
    node_url="${SN_NODE_URL_PREFIX}/sn_node-${NODE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  elif [[ ! -z "${NODE_BIN_PATH}" ]]; then
    if [[ -d "${NODE_BIN_PATH}" ]]; then
      echo "The node bin path must be a file"
      exit 1
    fi
    # The term 'custom' is used here rather than 'musl' because a locally built binary may not
    # be a musl build.
    local path=$(dirname "${NODE_BIN_PATH}")
    archive_name="sn_node-${testnet_channel}-x86_64-unknown-linux-custom.tar.gz"
    node_url="${SN_NODE_URL_PREFIX}/$archive_name"
    archive_path="/tmp/$archive_name"
    echo "Creating $archive_path..."
    # tar -C $path -zcvf $archive_path sn_node
    # echo "Uploading $archive_path to S3..."
    # aws s3 cp $archive_path s3://sn-node --acl public-read
  fi
  terraform apply \
    -var "do_token=${DO_PAT}" \
    -var "pvt_key=${SSH_KEY_PATH}" \
    -var "number_of_nodes=${NODE_COUNT}" \
    -var "node_url=${node_url}" \
    -var "client_count=${CLIENT_COUNT}" \
    --parallelism 15 ${AUTO_APPROVE}
}

function copy_ips_to_s3() {
  # This is only really used for debugging the nightly run.
  aws s3 cp \
    "$testnet_channel-ip-list" \
    "s3://sn-node/testnet_tool/$testnet_channel-ip-list" \
    --acl public-read
  aws s3 cp \
    "$testnet_channel-genesis-ip" \
    "s3://sn-node/testnet_tool/$testnet_channel-genesis-ip" \
    --acl public-read
}

function pull_network_contacts_and_copy_to_s3() {
  local genesis_ip=$(cat "$testnet_channel-genesis-ip")
  local network_contacts_path="$testnet_channel-network-contacts"
  echo "Pulling network contacts file from Genesis node"
  rsync root@"$genesis_ip":~/network-contacts "$network_contacts_path"
  aws s3 cp \
    "$network_contacts_path" \
    "s3://sn-node/testnet_tool/$testnet_channel-network-contacts" \
    --acl public-read
}

function pull_genesis_dbc_and_copy_to_s3() {
  local genesis_ip=$(cat "$testnet_channel-genesis-ip")
  local genesis_dbc_path="$testnet_channel-genesis-dbc"
  echo "Pulling Genesis DBC from Genesis node"
  rsync root@"$genesis_ip":~/node_data/genesis_dbc "$genesis_dbc_path"
  aws s3 cp \
    "$genesis_dbc_path" \
    "s3://sn-node/testnet_tool/$testnet_channel-genesis-dbc" \
    --acl public-read
}

function pull_genesis_key_and_copy_to_s3() {
  local genesis_ip=$(cat "$testnet_channel-genesis-ip")
  local genesis_key_path="$testnet_channel-genesis-key"
  echo "Pulling Genesis key from Genesis node"
  rsync root@"$genesis_ip":~/genesis-key "$genesis_key_path"
  aws s3 cp \
    "$genesis_key_path" \
    "s3://sn-node/testnet_tool/$testnet_channel-genesis-key" \
    --acl public-read
}

check_dependencies
run_terraform_apply
copy_ips_to_s3
pull_network_contacts_and_copy_to_s3
pull_genesis_dbc_and_copy_to_s3
pull_genesis_key_and_copy_to_s3
