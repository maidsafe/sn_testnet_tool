#!/bin/bash

# Modify the search_string variable to your desired search string
search_string=$1

echo "grepping for $1"

TESTNET_CHANNEL=$(terraform workspace show)

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

mkdir -p "workspace/${TESTNET_CHANNEL}/droplets"

export TESTNET_CHANNEL

# Function to perform ripgrep and sync matching files
perform_ripgrep_and_sync() {
  local name="$1"
  local ip="$2"
  local search_string="$3"

  if [[ -z $name || -z $ip ]]; then
    echo "$name $ip - Skipping line due to empty name or IP"
    return
  fi

  echo "Performing ripgrep for '$search_string' on $name ($ip)"
  ssh "root@$ip" "rg -lu '$search_string' ~/.local/share/safe/node/*" 

  if [[ -s /tmp/matching_files.txt ]]; then
    echo "Syncing matching files from $name ($ip)"
    mkdir -p "workspace/${TESTNET_CHANNEL}/droplets/${name}__${ip}"
    rsync -arz --files-from=/tmp/matching_files.txt --exclude"*" root@${ip}:~/ "workspace/${TESTNET_CHANNEL}/droplets/${name}__${ip}/"
  fi
}

# Get the input data from the file "workspace/${TESTNET_CHANNEL}/ip-list" using command substitution
input_data=$(< "workspace/${TESTNET_CHANNEL}/ip-list")

# Execute the function for each line of input data
echo "$input_data" | parallel --timeout 180 --colsep ' ' --jobs 10 \
  "perform_ripgrep_and_sync() {
    $(declare -f perform_ripgrep_and_sync)
    perform_ripgrep_and_sync \"\$@\"
  }; perform_ripgrep_and_sync {1} {2}"

echo "Logs updated"
