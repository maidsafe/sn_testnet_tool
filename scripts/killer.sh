#!/bin/bash

# Default destroy option
DESTROY="no"
PATTERN=""

# Usage function
usage() {
    echo "Usage: $0 [-d] PATTERN"
    exit 1
}

# Parse command-line arguments
for arg in "$@"
do
    if [[ "$arg" == "-d" ]]
    then
        DESTROY="yes"
    elif [[ -z "$PATTERN" && "$arg" != "-d" ]]
    then
        PATTERN="$arg"
    else
        echo "Unexpected argument: $arg"
        usage
    fi
done

# Check if pattern is provided
if [[ -z "$PATTERN" ]]; then
    usage
fi

# Array to store matched droplets
MATCHED_DROPLETS=()
echo "Matching droplets:"

# Get the list of all droplets
while read -r id droplet
do
    # Check if the droplet name matches the pattern
    if [[ $droplet =~ $PATTERN ]]; then
        echo "$droplet ($id)"
        # Add droplet id to array
        MATCHED_DROPLETS+=($id)
    fi
done < <(doctl compute droplet list --format ID,Name --no-header)

# Check if destroy option is set to yes
if [[ $DESTROY = "yes" && ${#MATCHED_DROPLETS[@]} -ne 0 ]]; then
    # Ask for confirmation before destroying droplets
    read -p "Do you really want to destroy all matched droplets? [y/N] " confirm
    if [[ $confirm = [yY] || $confirm = [yY][eE][sS] ]]; then
        for id in "${MATCHED_DROPLETS[@]}"; do
            # Destroy the droplet
            echo "Destroying droplet with id: $id"
            doctl compute droplet delete $id --force
        done
    else
        echo "Destruction cancelled."
    fi
else
    if [[ ${#MATCHED_DROPLETS[@]} -eq 0 ]]; then
        echo "No matching droplets found."
    fi
fi
