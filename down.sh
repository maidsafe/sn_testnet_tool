script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

terraform destroy -var "do_token=${DO_PAT}" -var "pvt_key=${1}"

rm ip-list || true
