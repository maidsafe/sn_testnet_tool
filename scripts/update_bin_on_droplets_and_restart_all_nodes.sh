#!/bin/bash

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

if [[ $# -eq 0 ]] ; then
    echo 'Error: No pattern provided. This would attempt to update all nodes, best not to do that'
    exit 1
fi

pattern=$1  # the pattern is passed as the first argument to the script

tmpfile=$(mktemp)  # create a temporary file

echo "Updating $TESTNET_CHANNEL nodes matching $pattern"
echo ""

export TESTNET_CHANNEL
export TZ=GMT

NODE1=$(echo "/ip4/$(cat ./workspace/$TESTNET_CHANNEL/contact-node)")

echo "NODE1 is $NODE1"
# Total count variable
total_count=0

# Define a function to run on each host
do_work() {
    pattern="$1"  # get pattern as a function argument
    ip="$2"  # get ip as a function argument
    node1="$3"  # get NODE1 as a function argument

    machine_name=$(ssh root@"$ip" hostname)
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    # If the machine name doesn't match the pattern, return immediately
    if [[ ! $machine_name =~ $pattern ]]; then
        # echo "Skipping $machine_name because it doesn't match the pattern $pattern" >&2
        return
    fi

    echo "Counting existing safenode processes on $machine_name at $timestamp"

    # Count the number of running safenode processes
    # existing_count=$(ssh root@"$ip" "pgrep -c safenode")
    existing_count=20

    echo "Found $existing_count existing safenode processes on $machine_name"

    echo "Killing safenode processes on $machine_name at $timestamp"
    ssh root@"$ip" killall safenode || echo "No safenode process to kill on $ip"

    echo "Uploading safenode file to $machine_name at $timestamp"
    scp "workspace/${TESTNET_CHANNEL}/safenode" root@"$ip":/root/

    echo "Uploaded safenode file to $machine_name $ip" >&2

    echo "Starting $existing_count safenode processes on $machine_name at $timestamp"
    
    for ((i = 1; i <= existing_count; i++)); do
        ssh root@"$ip" "nohup /root/.safenode --peer $node1 --log-dir ~/logs-updated-$i --root-dir ~/node_data_updated-$i > /dev/null 2>&1 &"
        echo "started node-$i"
        sleep 1
    done

    # Add the count to the total count
    ((total_count += existing_count))

    echo "Updated" >> "$tmpfile"  # write to the temporary file each time a machine is updated
}

# Export the function and tmpfile so that it's available to GNU Parallel
export -f do_work
export tmpfile

# Use GNU Parallel to run the function on each IP in parallel, passing NODE1 as an argument
cat workspace/${TESTNET_CHANNEL}/ip-list | awk -v p="$pattern" -v n="$NODE1" '{print p " " $2 " " n}' | parallel --colsep ' ' --jobs 0 do_work

# Count the number of lines in the temporary file, which represents the number of machines updated
droplets_updated=$(wc -l < "$tmpfile")

echo "$droplets_updated droplets updated."
echo "Total node processes started: $total_count"

rm "$tmpfile"  # delete the temporary file
