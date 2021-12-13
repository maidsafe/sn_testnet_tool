#!/bin/bash

echo "Downloading node binary to nodes"
node_version="latest"
node_url="https://sn-node.s3.eu-west-2.amazonaws.com/sn_node-${node_version}-x86_64-unknown-linux-musl.tar.gz"
wget ${node_url}
tar xf sn_node-${node_version}-x86_64-unknown-linux-musl.tar.gz
echo "Node bin downloaded"
