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

Create a network:
```
./up.sh <path-to-your-DO-registered-ssh-key> [number of nodes] [custom node bin location(must be musl)]
```

Bring down a network:

```
./down <path-to-your-DO-registered-ssh-key>
```

Get ips from aws:

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