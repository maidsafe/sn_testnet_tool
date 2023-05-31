#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
TESTNET_CHANNEL=$(terraform workspace show)

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

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

echo "$TESTNET_CHANNEL information:"
echo ""

total=0
droplets_accessed=0

args=""
if [[ "$print_records" == true ]]; then
  args+=" -r"
fi
if [[ "$print_memcpu" == true ]]; then
  args+=" -m"
fi

while read -r line; do
  echo "$line"
  if [[ $line == "Total safenode processes: "* ]]; then
    count=${line#"Total safenode processes: "}
    total=$((total + count))
    droplets_accessed=$((droplets_accessed + 1))
  fi
      # ssh root@"$ip" "bash -s" -- $args < /dev/null ./scripts/resource-usage-on-machine.sh
done < <(cat workspace/${TESTNET_CHANNEL}/ip-list | parallel --colsep ' ' -j0 "ssh root@{2} "bash -s" -- $args < ./scripts/resource-usage-on-machine.sh")
echo "$droplets_accessed droplets accessed in check."
echo "Grand total safenode processes: $total"

cleanup
