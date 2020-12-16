# SAFE Network Testnet Automation tool

This tool creates Digital Ocean droplets and deploys nodes to them starting a testnet. 
Adults nodes are killed and restarted at random intervals creating network churn.

## Instructions

```
export DIGITAL_OCEAN_TOKEN=<api-token>
export AWS_ACCESS_KEY_ID=AKIAVVODCRMSJ5MV63VB
export AWS_SECRET_ACCESS_KEY=<secret-key>
export AWS_DEFAULT_REGION=eu-west-2
cd scripts/
./start-testnet
```
