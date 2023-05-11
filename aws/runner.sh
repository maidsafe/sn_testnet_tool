#!/usr/bin/env bash
set -e

export $(cat .env | sed 's/#.*//g' | xargs)

# If no values are provided for the `--env` arguments, the values assigned will be the values
# of the same variables on the host machine.
docker run --rm --interactive --tty \
  --env AWS_ACCESS_KEY_ID --env AWS_SECRET_ACCESS_KEY --env AWS_DEFAULT_REGION \
  --env SSH_KEY_NAME --env DIGITALOCEAN_TOKEN --env DO_API_TOKEN \
  --env SN_TESTNET_DEV_SUBNET_ID --env SN_TESTNET_DEV_SECURITY_GROUP_ID \
  --volume $HOME/.ansible:/home/runner/.ansible \
  --volume $HOME/.ssh:/home/runner/.ssh \
  --volume $(pwd):/home/runner/sn_testnet_tool \
  sn_testnet_tool:latest
