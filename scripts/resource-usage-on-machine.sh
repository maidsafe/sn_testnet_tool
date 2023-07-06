#!/bin/bash

echo "Checking $(hostname) on $(hostname -I | awk '{print $1}')"
NODES_DIR=~/.local/share/safe/node
printf "%-65s %-8s %-10s %-10s %s\n" "Node PeerId" "PID" "Memory (MB)" "CPU (%)" "Record Count"
running_process_count=0
find "$NODES_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r folder; do
    node=$(basename "$folder")
    pid=$(cat "$folder/safenode.pid")
    if [ -z "$pid" ]; then
        echo "No PID found for $node"
        continue
    fi
    if [ ! -d "/proc/$pid" ]; then
        echo "PID $pid for $node is not currently running"
        continue
    fi
    rss=$(ps -p $pid -o rss=)
    cpu=$(top -b -n1 -p $pid | awk 'NR>7 {print $9}')
    count=$(find "$folder" -name '*' -not -name '*.pid' -type f | wc -l)
    printf "%-65s %-8s %-10s %-10s %s\n" "$node" "$pid" "$(awk "BEGIN {print $rss/1024}")" "$cpu" "$count"
    running_process_count=$((running_process_count + 1))
done

echo "$running_process_count"
