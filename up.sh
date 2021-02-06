# your local ssh key for connecting to nodes to deploy
SSH_KEY=${1}
NODE_OF_NODES=${2:-1}
# location of node file to upload
NODE_BIN=${3}
TWO_MB=$(( 2 * 1024 * 1024 ))
node_capacity=${1:-$TWO_MB}


terraform apply \
     -var "do_token=${DO_PAT}" \
     -var "pvt_key=${1}" \
     -var "number_of_nodes=${NODE_OF_NODES}" \
     -var "node_bin=${3}"

aws s3 cp ip-list s3://safe-testnet-tool/ip-list --acl public-read
aws s3 cp ip-list s3://safe-testnet-tool/genesis-ip --acl public-read
./scripts/register_keys.sh
