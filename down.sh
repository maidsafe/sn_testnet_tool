script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

terraform destroy -var "do_token=${DO_PAT}" -var "pvt_key=${1}"  --parallelism 15 && \
    rm ${TESTNET_CHANNEL}-ip-list || true
