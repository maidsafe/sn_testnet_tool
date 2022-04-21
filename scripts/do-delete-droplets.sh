#!/usr/bin/env bash

# Uses the `doctl` tool to delete Digital Ocean droplets matching a given name. 
# There's a confirm prompt to protect against removing machines you didn't intend to.

set -e

function usage() {
  echo "Usage: $0 -n/--name <string> -l/--list"
  echo "Use the --list argument to see which droplets you may want to remove."
  echo "Use the --name argument to remove droplets starting with a particular string."
  echo "Note: you will be prompted for confirmation before any droplets are deleted."
  exit 1
}

name=""
list=0

opts=$(getopt --name "delete-droplets" --options ln: --longoptions list,name: -- "$@")
eval set -- "$opts"
while true; do
  case "$1" in
    -l | --list)
      list=1
      shift
      ;;
    -n | --name)
      name="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Unexpected option: $1"
      usage
      ;;
  esac
done

if [[ ! -n "$name" ]] && [[ $list -eq 0 ]]; then usage; fi

if [[ $list -eq 1 ]]; then
  doctl compute droplet list --format ID,Name
  exit 0
fi

echo "Query for droplets whose name starts with $name..."
doctl compute droplet list --output json | jq ".[] | select(.name | startswith(\"$name\")) | .name"
read -p "Proceed to remove these? [y/n] " confirm
if [[ $confirm == "y" ]]; then
  list=( $(doctl \
    compute droplet list --output json | jq -r ".[] | select(.name | startswith(\"$name\")) | .id") )
  for droplet in "${list[@]}"
  do
    echo -n "Removing droplet $droplet..."
    doctl compute droplet delete "$droplet" --force
    echo "done"
  done
fi
