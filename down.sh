#!/bin/bash

if ! command -v terraform &> /dev/null
then
    echo "terraform could not be found and is required"
    exit
fi

DEFAULT_WORKING_DIR="."
WORKING_DIR="${WORKING_DIR:-$DEFAULT_WORKING_DIR}"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)
AUTO_APPROVE=${2}

terraform destroy -var "do_token=${DO_PAT}" -var "pvt_key=${1}" -var "working_dir=${WORKING_DIR}" --parallelism 15 ${AUTO_APPROVE} && \
    rm ${WORKING_DIR}/${TESTNET_CHANNEL}-ip-list || true
