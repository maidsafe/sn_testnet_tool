#!/bin/bash

set -e

SSH_KEY_PATH=${1}
NODE_OF_NODES=${2:-1}
NODE_BIN=${3}
NODE_VERSION=${4}
AUTO_APPROVE=${5}
DEFAULT_WORKING_DIR="."
WORKING_DIR="${WORKING_DIR:-$DEFAULT_WORKING_DIR}"

function check_dependencies() {
    set +e
    declare -a dependecies=("terraform" "aws" "tar")
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
    if [[ ! -z "${NODE_VERSION}" && ! -z "${NODE_BIN}" ]]; then
        echo "Both NODE_VERSION and NODE_BIN cannot be set at the same time."
        echo "Please use one or the other."
        exit 1
    fi
}

function run_terraform_apply() {
    local node_bin_path="${NODE_BIN}"
    if [[ ! -z "${NODE_VERSION}" ]]; then
        (
            cd /tmp
            rm -rf sn_node-${NODE_VERSION}
            mkdir sn_node-${NODE_VERSION}
            aws s3 cp s3://sn-node/sn_node-${NODE_VERSION}-x86_64-unknown-linux-musl.tar.gz .
            tar -C sn_node-${NODE_VERSION} -xvf sn_node-${NODE_VERSION}-x86_64-unknown-linux-musl.tar.gz
        )
        node_bin_path="/tmp/sn_node-${NODE_VERSION}/sn_node"
    fi
    terraform apply \
         -var "do_token=${DO_PAT}" \
         -var "pvt_key=${SSH_KEY_PATH}" \
         -var "number_of_nodes=${NODE_OF_NODES}" \
         -var "node_bin=${node_bin_path}" \
         -var "working_dir=${WORKING_DIR}" \
         --parallelism 15 ${AUTO_APPROVE}
}

function copy_ips_to_s3() {
    local testnet_channel=$(terraform workspace show)
    echo "$WORKING_DIR/$testnet_channel-ip-list"
    aws s3 cp \
        "$WORKING_DIR/$testnet_channel-ip-list" \
        "s3://safe-testnet-tool/$testnet_channel-ip-list" \
        --acl public-read
    aws s3 cp \
        "$WORKING_DIR/$testnet_channel-genesis-ip" \
        "s3://safe-testnet-tool/$testnet_channel-genesis-ip" \
        --acl public-read
}

function update_local_state() {
    ./scripts/register_keys.sh
    ./scripts/get-connection-infos
    local testnet_channel=$(terraform workspace show)
    aws s3 cp \
        "$WORKING_DIR/$testnet_channel-node_connection_info.config" \
        "s3://safe-testnet-tool/$testnet_channel-node_connection_info.config" \
        --acl public-read
}

check_dependencies
run_terraform_apply
copy_ips_to_s3
update_local_state
