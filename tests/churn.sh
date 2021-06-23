#!/bin/bash

# exit with any failed command
set -e

LOCAL_NODE_BUILD=${1}
STANDARD_WAIT="35"
INCREASED_COUNT=51
# actual reduction happens in loop below
REDUCED_COUNT="$INCREASED_COUNT"


function verify_data {
    echo ""
    echo "==> Checking files exist on the network"
    echo ""

    for details in $(ls $TMPDIR/addresses/data-address-*); do
        # check the files container
        container=$(jq -r '.[0]' "${details}")
        
        echo "safe cat ${container}"
        safe cat ${container} > /dev/null 
        # # check the file itself returns okay
        current_file=$(jq -r '.[1][][1]' "${details}")
        echo "safe cat ${current_file}"
        safe cat "${current_file}" > /dev/null
    done

    echo ""
    echo "==> All files could be retrieved fine so far"
    echo ""

}


function generate_data {
    echo ""
    echo "==> Generating data and putting it to the network"
    echo ""
    timestamp=$(date +"%T")

    # generate random files (count is how many mbs), so 1->4mb with 0..4 here
    for i in {1..7}; do
        echo "generating file of size ${i}mb"
        # worth noting "bs=1m" goes on mac, if its an issue on linux, it's "1M" (capital) needed, and we'll need a platform check here
        dd if=/dev/urandom of="$TMPDIR/files/randomfile-$timestamp-$i" bs=1m count=$i
        #RUST_LOG=sn_client=trace 
        echo "putting file $TMPDIR/files/randomfile-$timestamp-$i"
        safe files put "$TMPDIR/files/randomfile-$timestamp-$i" --json > "$TMPDIR/addresses/data-address-$timestamp-$i"
        echo "file put successfully"
    done
    echo ""
    echo "data uploaded"
    # this_wait=$(($STANDARD_WAIT * 4))
    echo "waiting $STANDARD_WAIT seconds for things to settle"
    echo ""
    sleep $STANDARD_WAIT
}

if ! command -v safe &> /dev/null
then
    echo "safe could not be found and is required"
    exit
fi

if ! command -v jq &> /dev/null
then
    echo "jq could not be found and is required"
    exit
fi
if ! command -v rg &> /dev/null
then
    echo "ripgrep could not be found and is required"
    exit
fi


if [[ -z "$LOCAL_NODE_BUILD" ]]; then
    echo "Must provide a local node build with \"always-joinable\" feature set" 1>&2
    exit 1
fi



current_space=$(terraform workspace show)
echo "==> Switching to the \"churn\" terraform workspace from $current_space."
echo ""
terraform workspace select churn



echo "==> First. An 11 node Network will be created using the \"$LOCAL_NODE_BUILD\" build (if it has been specified)."
echo ""
sleep 5
echo "terraforming..."
echo ""
# put up 11 nodes
./up.sh ~/.ssh/sharing_rsa 11 $LOCAL_NODE_BUILD -auto-approve  >/dev/null || exit
# Checking we're connected to the correct section info
config_count=$(( $(cat ~/.safe/node/node_connection_info.config | wc -l) - 1))
churn_ip_count=$(cat ./churn-ip-list | wc -l)


if ! [ $config_count -eq $churn_ip_count ]
    then
    echo "Config is not the same length as our churn ip count!!! $config_count, $churn_ip_count"
fi


echo ""
echo "> Using this new network"
echo ""
./scripts/use-network.sh

echo ""
echo "==> Now we're setup to use the testnet with the CLI"
echo ""

# cleanup locally
echo ""
echo "> Cleaning up any previously generated temp files"
echo ""

rm -rf $TMPDIR/files
rm -rf $TMPDIR/addresses

echo "==> Setting up the safe CLI with fresh tokens"
echo ""

# assuming we have the cli installed and up to date
safe keys create --test-coins --preload 1000000 --for-cli

echo ""
echo "> Making fresh local temp dirs"
echo ""

mkdir -p $TMPDIR/files
mkdir -p $TMPDIR/addresses


generate_data

verify_data


echo ""
echo "==> Increasing node count to split the section"
echo ""
echo "terraforming..."
echo ""
./up.sh ~/.ssh/sharing_rsa $INCREASED_COUNT $LOCAL_NODE_BUILD -auto-approve >/dev/null || exit


echo "Getting logfiles to check for split"
current_workspace=$(terraform workspace show)
./scripts/logs
# -u needed here to search log dirs
prefix_count=$(rg "Prefix\(0\)" ./logs/$current_workspace -u | wc -l)
if ! [ $prefix_count -gt 0 ]
    then
        echo "No split, try changing INCREASED_COUNT in the script!"
        exit 100
fi

echo ""
echo "==> The network has successfully split"
echo ""

echo "waiting for stability"
sleep $(($STANDARD_WAIT * 3))


echo ""
echo "> Using this updated network"
echo ""
./scripts/use-network.sh

verify_data


echo ""
echo "==> waiting $STANDARD_WAIT seconds for things to calm down on the network w/r/t PUT"
sleep $STANDARD_WAIT
echo "...wait over"


 for i in {1..4}; do       
    # currently limit drops to two at a time replica count is 3 so any more and we may loose chunks
    REDUCED_COUNT=$(( REDUCED_COUNT - 2 ))
    echo ""
    echo "==> Reducing our node count in the testnet to $REDUCED_COUNT"
    echo ""
    echo "terraforming..."
    echo ""
    ./up.sh ~/.ssh/sharing_rsa $REDUCED_COUNT $LOCAL_NODE_BUILD -auto-approve >/dev/null || exit


    echo ""
    echo "> Waiting $STANDARD_WAIT; network should be using AE to reseed lost chunks. (We now have ${REDUCED_COUNT} nodes.)"
    echo ""
    sleep $STANDARD_WAIT


    verify_data
       
done



echo ""
echo ""
echo "==> Tests Done! Things look good! "

echo "==> Bringing down the churn test-network"
./down.sh ~/.ssh/sharing_rsa -auto-approve >/dev/null || exit
echo "> Churn network has been destoyed"
echo ""
echo "==> Switching back to the $current_space terraform workspace."
echo ""
terraform workspace select $current_space

echo "==> Ciao!"
