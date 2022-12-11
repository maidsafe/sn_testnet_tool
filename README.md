# SAFE Network Testnet Automation tool

This tool creates Digital Ocean droplets and deploys nodes to them starting a testnet.
Adults nodes are killed and restarted at random intervals creating network churn.

## Instructions

Install terraform: https://learn.hashicorp.com/tutorials/terraform/install-cli

Get latest state:

```
export DO_PAT=<digital-oceaon-personal-access-token>
export AWS_ACCESS_KEY_ID=<access-key>
export AWS_SECRET_ACCESS_KEY=<secret-key>
export AWS_DEFAULT_REGION=<region, e.g. eu-west-2>
terraform init
terraform state pull
```

## Testnet Channels

We can create separate testnets using terraform workspaces. All commands/scripts will operate on the selected workspace.

To see your current workspace:

```
terraform workspace show
```

We generally use `alpha`, `beta` and `public` testnets. To switch to one

```
terraform workspace select alpha
```

### Creating a testnet

Once you have a workspace chosen you can create a test network:

```
./up.sh <path-to-your-DO-registered-ssh-key> [number of nodes] [local node bin path] [node version] [client count] [-auto-approve]
```

Example using defaults:

```
./up.sh ~/.ssh/id_rsa
```

That launches a testnet with 2 nodes, using the latest version of sn_node, and Terraform will prompt for approval.

Example using a specific version of `sn_node`:

```
./up.sh ~/.ssh/id_rsa 2 "" "0.10.0" "-auto-approve"
```

Example using a local `sn_node` binary:

```
./up.sh ~/.ssh/id_rsa 2 "/home/user/dev/safe_network/target/debug/sn_node" "" "-auto-approve"
```

Note: both [node bin] and [node version] can't be set at the same time. You must use one or the other (or neither).
Note 2: the absolute path to the node binary must be supplied.

There's also a utility Makefile, so you can launch a testnet with `make alpha` or `make beta` using a set of defaults. Set any of `SN_TESTNET_SSH_KEY_PATH`, `SN_TESTNET_NODE_COUNT`, `SN_TESTNET_NODE_BIN_PATH` or `SN_TESTNET_NODE_VERSION` to use custom versions of any of these. This launches the testnet with 20 nodes by default (to support file put/get), and also copies the connection information to `~/.safe/network_contacts/{channel}-network-contacts`.

Bring down a network:

```
./down <path-to-your-DO-registered-ssh-key>
```

This can also be done using `make clean-alpha` or `make clean-beta`.

Get ips from aws for your workspace:

```
./scripts/get-ips
```

Get logfiles (requires a populated ip file):

```
./scripts/logs
```

See continual network status:

```
./scripts/status
```

## Using the network

```
./scripts/use-network
```

Will copy the current workspace network-contacts to your `~/.safe/network_contacts/{testnet-channel}-network-contacts`

##  Building for profiling

the `./build` script will compile a _standard_ (non musl) version of `sn_node` which can be used with `heaptrack` for memory profiling.

To get the profiles the node in question will need to be stopped for the file to be written to.


## Scripts

### Check client progress

Ssh into client node and `rg` for `passed;` , display the output of the `sn_client` test runs. 

### Dl Files

Attempt to download files in `tests/index` using the `safe` bin.

### Do delete droplets

Should use digital ocean api to remove droplets matching a `name`. _Does not work on mac_

### get-all-mem-profile-data

ssh into each machine and grab the heaptrack data. Stores it in `workspace/<workspace>/memory-profiling`

### get-node-mem-profile-data

ssh into a specific machine and grab the heaptrack data. Stores it in `workspace/<workspace>/memory-profiling`

### get-ips

Grabs <workspace> genesis/nodes/client ip info from `aws`, and then `register_keys`

### init-client-node

Used during client node setup, grabs and builds code

### init-node

Used during network setup to get `sn_node` runninng on nodes, with `heaptrack` and other tooling installed

### logs

rsync the `logs` dir of each machine to `workspace/<workspace>/logs/<node>`

### latest-logs

rsync the latest `logs/sn_node.log` dir of each machine to `workspace/<workspace>/logs/<node>`

### loop-client-tests

Copied to the client node during init. Can be run on that machine to... loop client tests. Best run as `nohup ./loop_client_tests.sh &`.

### mem-usage

get mem usage using `pgrep` and print to console

### register-keys

a pre run of `ssh-keyscan` so other scripts can run more smoothly. Adds `workspace/<workspace>/ip-list`

### get-pids

ssh into each machine and store the PID in `workspace/<workspace>/pids`. A follow up of `show-broken-nodes` to see droplets where a process could not be found.

### show-broken-nodes

checks `workspace/<workspace>/pids` for "not found"` text, indicating a process is not running there

### stored-data-size-per-node

ssh in and checks the size of `node_data` folder

### ssh-into-node <node number>

eg `./scripts/ssh-into-node.sh 5` will ssh into the node 5 for you (using the `workspace/<workspace>/ip-list`)

### update-network-contacts

gets latest network contacts file from genesis (useful if there's beena split), stores it at `workspace/<workspace>/network-contacts`

### use-network

Sets your local `network-contacts` to be that of `workspace/<workspace>/network-contacts`