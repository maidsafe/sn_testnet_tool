#!/usr/bin/env just --justfile
set dotenv-load := true
enable_client := "false"
default_node_url := "https://sn-node.s3.eu-west-2.amazonaws.com/safenode-latest-x86_64-unknown-linux-musl.tar.gz"

# =============================================
# Public targets intended to be called by users
# =============================================

# Initialise the prequisites for creating the testnet:
# * Create a workspace for Terraform
# * Build the RCP client
# * Generate the inventory based on the template
# * Create an EC2 keypair based on the key at $HOME/.ssh/SSH_KEY_NAME
#
# This should be an idempotent target, in that it won't produce errors if any
# of the components already exist.
init env provider:
  #!/usr/bin/env bash
  (
    cd terraform/{{provider}}
    terraform init \
      -backend-config="bucket=$TERRAFORM_STATE_BUCKET_NAME" \
      -backend-config="region=$AWS_DEFAULT_REGION"
    terraform workspace list | grep -q "{{env}}"
    if [[ $? -eq 0 ]]; then
      echo "Workspace '{{env}}' already exists"
    else
      echo "Creating new Terraform workspace {{env}}"
      terraform workspace new {{env}}
    fi
  )

  just build-rpc-client
  just create-{{provider}}-inventory {{env}}
  just create-{{provider}}-keypair {{env}}

testnet env provider node_count:
  #!/usr/bin/env bash
  set -e
  (
    cd terraform/{{provider}}
    terraform workspace select {{env}}
  )
  just terraform-apply-{{provider}} "{{env}}" {{node_count}} false

  if [[ -f "bin/safenode" ]]; then
    echo "Custom safenode binary will be used"
    just upload-custom-node-bin "{{env}}" "{{provider}}" "bin/safenode"
  else
    sed "s|__NODE_URL__|{{default_node_url}}|g" -i ansible/extra_vars/.{{env}}_{{provider}}.json
  fi

  just wait-for-ssh "{{env}}" "{{provider}}"

  # Provision the genesis node
  just run-ansible-against-nodes "{{env}}" "{{provider}}" "true"

  # Provision the remaining nodes
  just run-ansible-against-nodes "{{env}}" "{{provider}}" "false"

# List the name and IP address of each node in the testnet, which can be used for SSH access.
ssh-details env provider:
  #!/usr/bin/env bash
  if [[ "{{provider}}" == "aws" ]]; then
    ansible-inventory --inventory ansible/inventory/.{{env}}_inventory_aws_ec2.yml --list | \
      jq -r '._meta.hostvars | to_entries[] | [.value.tags.Name, .value.public_dns_name] | @tsv' | \
      column -t | \
      sort
    echo "The user for the EC2 instances is 'ubuntu'"
  elif [[ "{{provider}}" == "digital-ocean" ]]; then
    ansible-inventory --inventory ansible/inventory/.{{env}}_inventory_digital_ocean.yml --list | \
      jq -r '._meta.hostvars | to_entries[] | [.value.do_name, .value.ansible_host] | @tsv' | \
      column -t | \
      sort
    echo "The user for the droplets is 'root'"
  else
    echo "Provider {{provider}} is not supported"
    echo "Please use 'aws' or 'digital-ocean' as the provider"
    exit 1
  fi

# Retrieve the logs for each node in the testnet.
logs env provider:
  #!/usr/bin/env bash
  set -e

  (
    if [[ "{{provider}}" == "aws" ]]; then
      user="ubuntu"
      inventory_path="inventory/.{{env}}_inventory_aws_ec2.yml"
    elif [[ "{{provider}}" == "digital-ocean" ]]; then
      user="root"
      inventory_path="inventory/.{{env}}_inventory_digital_ocean.yml"
    else
      echo "Provider {{provider}} is not supported"
      exit 1
    fi

    cd ansible
    rm -rf logs
    mkdir logs
    ansible-playbook --inventory $inventory_path \
      --private-key $HOME/.ssh/$SSH_KEY_NAME \
      --extra-vars "@extra_vars/.{{env}}_{{provider}}.json" \
      --user $user \
      --forks 30 \
      logs.yml
  )
  (
    cd ansible/logs
    for tar_file in *.tar.gz
    do
      dir_name="${tar_file%.tar.*}"
      mkdir $dir_name
      tar xvf $tar_file -C $dir_name
      rm $tar_file
    done
    find . -type d -name "logs" -depth -exec rm -rf "{}" \;
  )
  rm -rf logs
  mv ansible/logs .

# Tear down all the EC2 instances or droplets in the testnet and delete the Terraform workspace.
clean env provider:
  #!/usr/bin/env bash
  set -e

  just terraform-destroy-{{provider}} "{{env}}"
  (
    cd terraform/{{provider}}
    terraform workspace select dev
    output=$(terraform workspace list)
    if [[ "$output" == *"{{env}}"* ]]; then
      echo "Deleting {{env}} workspace..."
      terraform workspace delete -force {{env}}
    fi
  )
  just clean-{{provider}} "{{env}}"

# =============================================================
# Private helper utility targets intended to reduce duplication
# =============================================================

# Put the user's custom node binary on S3.
#
# The binary will be placed in a tar archive and placed in a folder within the bucket.
# Using the folder enables each testnet user to have their own binary without interfering
# with each other.
#
# The extra vars file will also be populated with the resulting URL of the archive and
# it will be pulled during the provisioning process. Uploading it once prevents Ansible from
# having to upload it to each node from the client, which is very time consuming.
upload-custom-node-bin env provider node_bin_path:
  #!/usr/bin/env bash
  archive_name="safenode-custom-x86_64-unknown-linux.tar.gz"
  rm -rf /tmp/custom_node && mkdir /tmp/custom_node
  cp {{node_bin_path}} /tmp/custom_node
  (
    cd /tmp/custom_node
    tar -zcvf $archive_name safenode
  )
  aws s3 cp /tmp/custom_node/$archive_name s3://sn-node/{{env}}/$archive_name --acl public-read
  url="https://sn-node.s3.eu-west-2.amazonaws.com/{{env}}/${archive_name}"
  sed "s|__NODE_URL__|$url|g" -i ansible/extra_vars/.{{env}}_{{provider}}.json
  echo "Custom binary available at $url"

# Set the multiaddr of the genesis node for provisioning the remaining nodes.
#
# The IP of the genesis node is obtained, then we use that with the RPC service to get
# its peer ID.
#
# The placeholder value in the variables file is then replaced. This file gets provided
# to Ansible.
set-genesis-multiaddr env provider:
  #!/usr/bin/env bash
  set -e
  if [[ "{{provider}}" == "aws" ]]; then
    inventory_path="inventory/.{{env}}_genesis_inventory_aws_ec2.yml"
    cd ansible
    genesis_ip=$(ansible-inventory --inventory $inventory_path --list | \
      jq -r '.["_meta"]["hostvars"][]["public_ip_address"]')
    cd ..
  elif [[ "{{provider}}" == "digital-ocean" ]]; then
    inventory_path="inventory/.{{env}}_genesis_inventory_digital_ocean.yml"
    cd ansible
    genesis_ip=$(ansible-inventory --inventory $inventory_path --list | \
      jq -r '.["_meta"]["hostvars"][]["ansible_host"]')
    cd ..
  fi

  peer_id=$(./safenode_rpc_client $genesis_ip:12001 info | \
    grep "Peer Id" | awk -F ':' '{ print $2 }' | xargs)
  multiaddr="/ip4/$genesis_ip/udp/12000/quic-v1/p2p/$peer_id"
  echo "Multiaddr for genesis node is $multiaddr"
  sed "s|__MULTIADDR__|$multiaddr|g" -i ansible/extra_vars/.{{env}}_{{provider}}.json

wait-for-ssh env provider:
  #!/usr/bin/env bash
  if [[ "{{provider}}" == "aws" ]]; then
    inventory_path="inventory/.{{env}}_genesis_inventory_aws_ec2.yml"
    cd ansible
    genesis_ip=$(ansible-inventory --inventory $inventory_path --list | \
      jq -r '.["_meta"]["hostvars"][]["public_ip_address"]')
    cd ..
    user="ubuntu"
  elif [[ "{{provider}}" == "digital-ocean" ]]; then
    inventory_path="inventory/.{{env}}_genesis_inventory_digital_ocean.yml"
    cd ansible
    genesis_ip=$(ansible-inventory --inventory $inventory_path --list | \
      jq -r '.["_meta"]["hostvars"][]["ansible_host"]')
    cd ..
    user="root"
  fi

  max_retries=10
  count=0
  until ssh -q -oBatchMode=yes -oConnectTimeout=5 -oStrictHostKeyChecking=no $user@$genesis_ip "bash --version"; do
    sleep 5
    count=$((count + 1))
    if [[ $counter -gt $max_retries ]]; then
      echo "SSH command failed after $count attempts. Exiting."
      exit 1
    fi
    echo "SSH still not available. Attempt $count of $max_retries. Retrying in 5 seconds..."
  done
  echo "SSH connection now available"

# Build a copy of the RCP client, which is used for obtaining the genesis peer ID.
# If the binary is already in the current directory we will skip.
build-rpc-client:
  #!/usr/bin/env bash
  if [[ ! -f ./safenode_rpc_client ]]; then
    (
      cd /tmp
      git clone https://github.com/maidsafe/safe_network
      cd safe_network
      cargo build --release --example safenode_rpc_client
    )
    cp /tmp/safe_network/target/release/examples/safenode_rpc_client .
  else
    echo "The safenode_rpc_client binary is already present"
  fi

run-ansible-against-nodes env="" provider="" is_genesis="":
  #!/usr/bin/env bash
  set -e
  
  if [[ "{{is_genesis}}" == "true" ]]; then
    playbook="genesis_node.yml"
    inventory_path="inventory/.{{env}}_genesis_inventory"
  else
    just set-genesis-multiaddr "{{env}}" "{{provider}}"
    playbook="nodes.yml"
    inventory_path="inventory/.{{env}}_node_inventory"
  fi

  if [[ "{{provider}}" == "aws" ]]; then
    user="ubuntu"
    inventory_path="${inventory_path}_aws_ec2.yml"
  elif [[ "{{provider}}" == "digital-ocean" ]]; then
    user="root"
    inventory_path="${inventory_path}_digital_ocean.yml"
  else
    echo "Provider {{provider}} is not supported"
    exit 1
  fi

  extra_vars_path="extra_vars/.{{env}}_{{provider}}.json"
  just run-ansible "$user" "$inventory_path" "$playbook" "$extra_vars_path"

run-ansible user inventory_path playbook extra_vars_path:
  #!/usr/bin/env bash
  set -e
  (
    cd ansible
    ansible-playbook --inventory {{inventory_path}} \
      --private-key $HOME/.ssh/$SSH_KEY_NAME \
      --user {{user}} \
      --extra-vars "@{{extra_vars_path}}" \
      --vault-password-file $HOME/.ansible/vault-password \
      {{playbook}}
  )

# ===========
# AWS helpers
# ===========
create-aws-keypair env:
  #!/usr/bin/env bash
  key_name="testnet-{{env}}"
  if ! aws ec2 describe-key-pairs --key-names "$key_name" > /dev/null 2>&1; then
    pub_key=$(cat $HOME/.ssh/${SSH_KEY_NAME}.pub | base64 -w0 | xargs)
    echo "Creating new key pair for the testnet..."
    aws ec2 import-key-pair \
      --key-name testnet-{{env}} --public-key-material $pub_key
  else
    echo "An EC2 keypair for {{env}} already exists"
  fi

create-aws-inventory env:
  cp ansible/inventory/dev_genesis_inventory_aws_ec2.yml \
    ansible/inventory/.{{env}}_genesis_inventory_aws_ec2.yml
  sed "s/dev/{{env}}/g" -i ansible/inventory/.{{env}}_genesis_inventory_aws_ec2.yml

  cp ansible/inventory/dev_node_inventory_aws_ec2.yml \
    ansible/inventory/.{{env}}_node_inventory_aws_ec2.yml
  sed "s/dev/{{env}}/g" -i ansible/inventory/.{{env}}_node_inventory_aws_ec2.yml

  cp ansible/inventory/dev_client_inventory_aws_ec2.yml \
    ansible/inventory/.{{env}}_client_inventory_aws_ec2.yml
  sed "s/dev/{{env}}/g" -i ansible/inventory/.{{env}}_client_inventory_aws_ec2.yml

  cp ansible/inventory/dev_inventory_aws_ec2.yml \
    ansible/inventory/.{{env}}_inventory_aws_ec2.yml
  sed "s/dev/{{env}}/g" -i ansible/inventory/.{{env}}_inventory_aws_ec2.yml

  cp ansible/extra_vars/aws.json ansible/extra_vars/.{{env}}_aws.json

terraform-apply-aws env node_count enable_client:
  #!/usr/bin/env bash
  cd terraform/aws
  terraform apply -auto-approve \
    -var node_count={{node_count}} \
    -var key_pair_name=testnet-{{env}} \
    -var vpc_subnet_id="$SN_TESTNET_DEV_SUBNET_ID" \
    -var vpc_security_group_id="$SN_TESTNET_DEV_SECURITY_GROUP_ID" \
    -var enable_client={{enable_client}}

terraform-destroy-aws env:
  #!/usr/bin/env bash
  cd terraform/aws
  terraform workspace select {{env}}
  terraform destroy -auto-approve \
    -var key_pair_name=testnet-{{env}} \
    -var vpc_subnet_id="$SN_TESTNET_DEV_SUBNET_ID" \
    -var vpc_security_group_id="$SN_TESTNET_DEV_SECURITY_GROUP_ID"

clean-aws env:
  #!/usr/bin/env bash
  output=$(aws ec2 describe-key-pairs | jq -r '.KeyPairs[].KeyName')
  if [[ "$output" == *"testnet-{{env}}"* ]]; then
    echo -n "Deleting keypair..."
    aws ec2 delete-key-pair --key-name testnet-{{env}}
    echo "Done"
  fi
  rm -f ansible/inventory/.{{env}}_genesis_inventory_aws_ec2.yml
  rm -f ansible/inventory/.{{env}}_node_inventory_aws_ec2.yml
  rm -f ansible/inventory/.{{env}}_inventory_aws_ec2.yml
  rm -f ansible/extra_vars/.{{env}}_aws.json

# ===========
# DO helpers
# ===========
create-digital-ocean-keypair env:
  @echo "Digital Ocean does not require the creation of a keypair"

create-digital-ocean-inventory env:
  cp ansible/inventory/dev_inventory_digital_ocean.yml \
    ansible/inventory/.{{env}}_genesis_inventory_digital_ocean.yml
  sed "s/env_value/{{env}}/g" -i ansible/inventory/.{{env}}_genesis_inventory_digital_ocean.yml
  sed "s/type_value/genesis/g" -i ansible/inventory/.{{env}}_genesis_inventory_digital_ocean.yml

  cp ansible/inventory/dev_inventory_digital_ocean.yml \
    ansible/inventory/.{{env}}_node_inventory_digital_ocean.yml
  sed "s/env_value/{{env}}/g" -i ansible/inventory/.{{env}}_node_inventory_digital_ocean.yml
  sed "s/type_value/node/g" -i ansible/inventory/.{{env}}_node_inventory_digital_ocean.yml

  cp ansible/inventory/dev_inventory_digital_ocean.yml \
    ansible/inventory/.{{env}}_inventory_digital_ocean.yml
  sed "s/env_value/{{env}}/g" -i ansible/inventory/.{{env}}_inventory_digital_ocean.yml
  sed '$d' -i ansible/inventory/.{{env}}_inventory_digital_ocean.yml

  cp ansible/extra_vars/digital_ocean.json ansible/extra_vars/.{{env}}_digital-ocean.json

terraform-apply-digital-ocean env node_count enable_client:
  #!/usr/bin/env bash
  cd terraform/digital-ocean
  terraform apply -auto-approve -var node_count={{node_count}}

terraform-destroy-digital-ocean env:
  #!/usr/bin/env bash
  cd terraform/digital-ocean
  terraform workspace select {{env}}
  terraform destroy -auto-approve

clean-digital-ocean env:
  #!/usr/bin/env bash
  rm -f ansible/inventory/.{{env}}_genesis_inventory_digital_ocean.yml
  rm -f ansible/inventory/.{{env}}_node_inventory_digital_ocean.yml
  rm -f ansible/inventory/.{{env}}_inventory_digital_ocean.yml
  rm -f ansible/extra_vars/.{{env}}_digital-ocean.json
