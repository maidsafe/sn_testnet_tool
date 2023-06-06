#!/bin/bash

NODE=1
ITERATIONS=100
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

echo "Setting up looping downloads of test-data via $OUR_NODE_IP to $NODE1"

# Create a directory to store the log files
ssh root@$OUR_NODE_IP "mkdir -p download-logs"

# SSH into the remote machine and run the looping command in the background
ssh root@$OUR_NODE_IP "nohup bash -c 'for ((i=1; i<=$ITERATIONS; i++)); do time safe --peer $NODE1 files download > download-logs/\$i.log 2>&1 && sleep 15; done' > /dev/null 2>&1 & echo \$! > loop_pid"

echo "Download looping underway"
