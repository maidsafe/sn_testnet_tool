#!/bin/bash

ELASTIC=${1}
KIBANA=${2}

# Make sure we have both the IPs passed as arguments
if [[ -z "${ELASTIC}" ]]; then
    echo "Please provide ElasticSearch machine's public IP as the first argument"
    exit 1
fi

if [[ -z "${KIBANA}" ]]; then
    echo "Please provide Kibana machine's public IP as the second argument"
    exit 1
fi

if [[ -z "${AWS_ACCESS_KEY_ID}" ]]; then
    echo "The AWS_ACCESS_KEY_ID env variable must be set with your access key ID."
    exit 1
fi

if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
    echo "The AWS_SECRET_ACCESS_KEY env variable must be set with your secret access key."
    exit 1
fi

if [[ -z "${AWS_DEFAULT_REGION}" ]]; then
    echo "The AWS_DEFAULT_REGION env variable must be set. Default is usually eu-west-2."
    exit 1
fi


# Replace the IP place holders with
sed -e "s/<ELASTIC-MACHINE-PUBLIC-IP>/${ELASTIC}/g" -e "s/<KIBANA-MACHINE-PUBLIC-IP>/${KIBANA}/g" ./scripts/ELK/templates/metricbeat.yml > metricbeat.yml

# Upload the updated config to s3 for nodes to use
aws s3 cp metricbeat.yml s3://sn-node/testnet_tool/metricbeat.yml --acl public-read

# Remove the backup file that is created by using sed
rm metricbeat.yml