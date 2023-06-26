#!/bin/bash
DROPLET=${1}
NODE=${2}
TESTNET_CHANNEL=$(terraform workspace show)

target_droplet="droplet-$DROPLET"
target_node="logs-$NODE"

echo "Trying rsync ${target_node} from droplet $target_droplet"

ips=$(cat workspace/$(terraform workspace show)/ip-list)
# <<< echo... prevents the while running in a subshell so we can set our var
while read line; do
  name=$(echo $line | awk '{print $1}')
  ip=$(echo $line | awk '{print $2}')
  if [ $name == $target_droplet ]; then 
    OUR_NODE_IP="$ip"
  fi
done <<< "$(echo -e "$ips")"

echo "ssh would be root@$OUR_NODE_IP"

rsync -arz --include "logs**" --exclude "*" root@${OUR_NODE_IP}:~/${target_node} $target_node
rsync -arz --include "node-data**" --exclude "*" root@${OUR_NODE_IP}:~/${target_node} $target_node
