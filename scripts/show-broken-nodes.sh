#!/bin/bash


TESTNET_CHANNEL=$(terraform workspace show)

#!/bin/bash

# Concatenate and display killed.log files
rg -u "Killed.+safe" ./workspace/${TESTNET_CHANNEL}/logs/**/killed.log;


