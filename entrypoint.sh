#!/bin/bash

set -e

export DIGITALOCEAN_TOKEN=${DO_PAT}
export DO_API_TOKEN=${DO_PAT}

exec "$@"
