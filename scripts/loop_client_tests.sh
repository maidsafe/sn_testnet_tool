#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}


cd safe_network/sn_client

# run 50 times, increment counter once per iter
for i in {0..50..1}
do
  echo "iteration $i, time:"
  RUST_LOG=sn_client cargo test --release -- --skip spent > ../../test-$i.log || true
done

cd -


cleanup
