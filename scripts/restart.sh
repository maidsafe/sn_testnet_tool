#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

GB=$(( 1024 * 1024 * 1024 * 10))
MAX_CAPACITY=${1:-${GB}}
GENESIS_IP=$( cat ${TESTNET_CHANNEL}-genesis-ip)
# HARD_CODED_CONTACTS="[\"${GENESIS_IP}:12000\"]"
HARD_CODED_CONTACTS='[\"'$GENESIS_IP':12000\"]'

echo "restarting genesis node"

ssh root@$GENESIS_IP 'pkill -f sn_node & rm ~/nohup.out || true && nohup 2>&1 ./sn_node --first '$GENESIS_IP':12000 --skip-igd --root-dir ~/node_data -vvvvv &' 

echo "waiting for gensis to start properly"
sleep 15

#  ensure ips are registered
echo "Restarting all nodes w/ system"

echo $MAX_CAPACITY
echo $HARD_CODED_CONTACTS
for ip in $(cat ${TESTNET_CHANNEL}-ip-list | awk '{print $2}'); do
    if [ "$ip" == "$GENESIS_IP" ]; then
        echo "Not restarting genesis node again. Doing nothing here"
    else
        echo "restarting node at $ip"
        ssh root@${ip} 'pkill -f sn_node & rm ~/nohup.out || true && nohup 2>&1 ./sn_node --max-capacity '$MAX_CAPACITY' --root-dir ~/node_data --hard-coded-contacts '$HARD_CODED_CONTACTS' -vvvvv --skip-igd &' &
    fi
done

echo "All ${TESTNET_CHANNEL} Nodes restarted."
