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

export $(cat .env | sed 's/#.*//g' | xargs)

docker run --rm --tty \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY --env AWS_DEFAULT_REGION \
  --env SSH_KEY_NAME --env DO_PAT --env SN_TESTNET_DEV_SUBNET_ID \
  --env SN_TESTNET_DEV_SECURITY_GROUP_ID \
  --volume $HOME/.ansible:/home/runner/.ansible \
  --volume $HOME/.ssh:/home/runner/.ssh \
  --volume $(pwd):/home/runner/sn_testnet_tool \
  jacderida/sn_testnet_tool:latest just clean $env $provider
