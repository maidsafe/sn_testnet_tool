#!/bin/bash
NODE=1
TESTNET_CHANNEL=$(terraform workspace show)

target_node="droplet-$NODE"

echo "Trying to ssh into $target_node"

ips=$(cat workspace/$(terraform workspace show)/ip-list)
# <<< echo... prevents the while running in a subshell so we can set our var
while read line; do
  name=$(echo $line | awk '{print $1}')
  ip=$(echo $line | awk '{print $2}')
  if [ $name == $target_node ]; then 
    OUR_NODE_IP="$ip"
  fi
done <<< "$(echo -e "$ips")"

NODE1=$(echo "/ip4/$(cat ./workspace/$TESTNET_CHANNEL/contact-node)")

echo "trying to download via $OUR_NODE_IP to $NODE1"
ssh root@$OUR_NODE_IP "time safe --peer $NODE1 files  download "

# time safe files upload test-data/