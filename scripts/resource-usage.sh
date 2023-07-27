#!/bin/bash

NODE_DATA_DIR_PATH=~/.local/share/safe/node
LOGFILE=$NODE_DATA_DIR_PATH/resource-usage.log

exec > >(tee -a $LOGFILE) 2>&1

while true; do
  echo "------------------------------------------------------"
  echo "Report for $(date)"
  echo "------------------------------------------------------"
  echo "Checking $(hostname) on $(hostname -I | awk '{print $1}')"
  printf "%-52s %-8s %-10s %-10s %s\n" \
    "Node                                                " \
    "PID" \
    "Memory (MB)" \
    "CPU (%)" \
    "Record Count"
  running_process_count=0
  for folder in $NODE_DATA_DIR_PATH/*; do
    if [ ! -d "$folder" ]; then continue; fi
    peer_id=$(basename "$folder")
    pid=$(cat "$folder/safenode.pid")
    if [ -z "$pid" ]; then
      echo "No PID found for $peer_id"
      continue
    fi
    if [ ! -d "/proc/$pid" ]; then
      echo "PID $pid for $peer_id is not currently running"
      continue
    fi
    rss=$(ps -p $pid -o rss=)
    cpu=$(top -b -n1 -p $pid | awk 'NR>7 {print $9}')
    count=$(find "$folder" -name '*' -not -name '*.pid' -type f | wc -l)
    printf "%-52s %-8s %-10s %-10s %s\n" \
      "$peer_id" \
      "$pid" \
      "$(awk "BEGIN {print $rss/1024}")" \
      "$cpu" \
      "$count"
    running_process_count=$((running_process_count + 1))
  done
  echo "Total node processes: $running_process_count"
  sleep 10
done
