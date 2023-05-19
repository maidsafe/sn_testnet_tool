#!/bin/bash

os=$(uname)
if [ "$os" = "Linux" ]; then
  echo "Running on Linux. We will use Dockerfile for the build."
  dockerfile="Dockerfile"
elif [ "$os" = "Darwin" ]; then
  echo "Running on macOS. We will use Dockerfile.arm64 for the build."
  dockerfile="Dockerfile.arm64"
else
  echo "Unsupported operating system. Please run this script on Linux or macOS."
  exit 1
fi

docker rm -f $(docker ps -a -q --filter ancestor=sn_testnet_tool:latest)
docker rmi -f sn_testnet_tool:latest
docker build -t sn_testnet_tool:latest -f $dockerfile .
