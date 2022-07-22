#!/bin/bash

if ! command -v terraform &> /dev/null
then
  echo "terraform could not be found and is required"
  exit
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)
AUTO_APPROVE=${2}

terraform destroy \
  -var "do_token=${DO_PAT}" \
  -var "pvt_key=${1}" \
  --parallelism 15 ${AUTO_APPROVE} && \
  rm ${TESTNET_CHANNEL}-ip-list || true

aws s3 rm "s3://safe-testnet-tool/$TESTNET_CHANNEL-ip-list"
aws s3 rm "s3://safe-testnet-tool/$TESTNET_CHANNEL-genesis-ip"
aws s3 rm "s3://safe-testnet-tool/$TESTNET_CHANNEL-prefix-map"
