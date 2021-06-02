#!/bin/bash

# Uploads 20 files of 1MB each
safe keys create --test-coins --preload 1000000 --for-cli
timestamp=$(date +"%T")
mkdir -p files
mkdir -p addresses
for i in {0..1}; do
	dd if=/dev/urandom of=files/randomfile-$timestamp-$i bs=1M count=1
	safe files put files/randomfile-$timestamp-$i  --json > addresses/data-address-$timestamp-$i
done

