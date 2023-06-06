#!/bin/bash


TESTNET_CHANNEL=$(terraform workspace show)

#!/bin/bash

# Concatenate and display killed.log files
rg -u "Killed" ./workspace/${TESTNET_CHANNEL}/logs/**/killed.log;


