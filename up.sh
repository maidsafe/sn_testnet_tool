#!/usr/bin/env bash
set -e

env="$1"
if [[ -z "$env" ]]; then
  echo "A name for the environment must be provided"
  exit 1
fi

provider="$2"
if [[ -z "$provider" ]]; then
  echo "The cloud provider must be specified"
  echo "Valid values are 'aws' or 'digital-ocean'"
  exit 1
fi

node_count="$3"
if [[ -z "$node_count" ]]; then
  echo "The number of nodes must be provided"
  exit 1
fi

custom_bin="$4"

org="$5"
if [[ "$custom_bin" = true && -z "$org" ]]; then
  echo "If using a custom binary the Github organisation or user must be provided"
  exit 1
fi

branch="$6"
if [[ "$custom_bin" = true && -z "$branch" ]]; then
  echo "If using a custom binary the Github branch must be provided"
  exit 1
fi

export $(cat .env | sed 's/#.*//g' | xargs)

docker run --rm \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY --env AWS_DEFAULT_REGION \
  --env SSH_KEY_NAME --env DO_PAT --env SN_TESTNET_DEV_SUBNET_ID \
  --env SN_TESTNET_DEV_SECURITY_GROUP_ID --env TERRAFORM_STATE_BUCKET_NAME \
  --env DIGITALOCEAN_TOKEN --env DO_API_TOKEN \
  --volume $HOME/.ansible:/home/runner/.ansible \
  --volume $HOME/.ssh:/home/runner/.ssh \
  --volume $(pwd):/home/runner/sn_testnet_tool \
  jacderida/sn_testnet_tool:latest just init $env $provider
docker run --rm --tty \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY --env AWS_DEFAULT_REGION \
  --env SSH_KEY_NAME --env DO_PAT --env SN_TESTNET_DEV_SUBNET_ID \
  --env SN_TESTNET_DEV_SECURITY_GROUP_ID --env TERRAFORM_STATE_BUCKET_NAME \
  --env DIGITALOCEAN_TOKEN --env DO_API_TOKEN \
  --volume $HOME/.ansible:/home/runner/.ansible \
  --volume $HOME/.ssh:/home/runner/.ssh \
  --volume $(pwd):/home/runner/sn_testnet_tool \
  jacderida/sn_testnet_tool:latest just testnet $env $provider $node_count $custom_bin $org $branch
