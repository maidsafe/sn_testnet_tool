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
terraform workspace use alpha
```


### Creating a testnet

Once you have a workspace chosen you can create a test network:
```
./up.sh <path-to-your-DO-registered-ssh-key> [number of nodes] [custom node bin location(must be musl)]
```

Bring down a network:

```
./down <path-to-your-DO-registered-ssh-key>
```

Get ips from aws for your workspace:

```
./scripts/get-ips
```

Get logfiles (requires a populated ip file):

```
./scripts/get-logfiles
```

See continual network status:

```
./scripts/status
```

## Using the network

```
./scripts/use-network
```

Will copy the current workspace config to you `~/.safe/node/node_connection_info.config