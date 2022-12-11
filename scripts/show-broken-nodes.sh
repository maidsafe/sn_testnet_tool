#!/bin/bash


TESTNET_CHANNEL=$(terraform workspace show)

echo "to be run after \"get-pids\" script..."

rg "not found" workspace/$TESTNET_CHANNEL/pids -u -c