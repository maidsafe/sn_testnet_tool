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
./up.sh <path-to-your-DO-registered-ssh-key> [number of nodes] [node bin] [node version] [-auto-approve]
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
./up.sh ~/.ssh/id_rsa 2 "~/dev/safe_network/target/debug/sn_node" "" "-auto-approve"
```

Note: both [node bin] and [node version] can't be set at the same time. You must use one or the other (or neither).

There's also a utility Makefile, so you can launch a testnet with `make alpha` or `make beta` using a set of defaults. Set any of `SN_TESTNET_SSH_KEY_PATH`, `SN_TESTNET_NO_OF_NODES`, `SN_TESTNET_NODE_BIN` or `SN_TESTNET_NODE_VERSION` to use custom versions of any of these. This launches the testnet with 20 nodes by default (to support file put/get), and also copies the connection information to `~/.safe/prefix_maps/{channel}-prefix-map`.

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

Will copy the current workspace prefix-map to your `~/.safe/prefix_maps/{testnet-channel}-prefix-map`

##  Building for profiling

the `./build` script will compile a _standard_ (non musl) version of `sn_node` which can be used with `heaptrack` for memory profiling.

To get the profiles the node in question will need to be stopped for the file to be written to.