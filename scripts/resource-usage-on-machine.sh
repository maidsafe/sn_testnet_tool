#!/bin/bash
print_records=false
print_memcpu=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -r|--records)
        print_records=true
        shift
        ;;
        -m|--memcpu)
        print_memcpu=true
        shift
        ;;
        *)
        echo "Unknown option: $key"
        exit 1
        ;;
    esac
done

echo "Checking $(hostname -I | awk '{print $1}')..."
echo ""

if [[ $print_records == true ]]; then
    node_data_folders=~/node_data-*/
    printf "%-15s %s\n" "Node" "Record Count"
    for folder in $node_data_folders; do
        node=$(basename "$folder")
        count=$(find "$folder" -type f | wc -l)
        printf "%-15s %s\n" "$node" "$count"
    done
    echo ""
fi

pids=$(pgrep safenode)
if [[ $print_memcpu == true ]]; then
    printf "%-8s %-10s %-10s\n" "PID" "Memory (MB)" "CPU (%)"
    for pid in $pids; do
        rss=$(ps -p $pid -o rss=)
        cpu=$(top -b -n1 -p $pid | awk 'NR>7 {print $9}')
        printf "%-8s %-10s %-10s\n" "$pid" "$(awk "BEGIN {print $rss/1024}")" "$cpu"
    done
    echo ""
fi

count=$(echo "$pids" | wc -l)
echo "Total safenode processes: $count"
echo ""
