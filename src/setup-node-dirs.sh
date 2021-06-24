#!/bin/bash

echo "Setting up node dirs"
mkdir -p ~/node_data
mkdir -p ~/.safe/node
mkdir -p ~/logs
echo "" > ~/.safe/node/node_connection_info.config
chmod +x sn_node
echo "Node dirs setup, and node bin is executable"
