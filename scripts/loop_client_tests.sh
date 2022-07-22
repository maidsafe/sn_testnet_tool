#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

LOOP_COUNT=${1:-5}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

run_test_loop() {

  cd safe_network/sn_client

  # run LOOP_COUNT times, increment counter once per iter
  for i in {0..$LOOP_COUNT..1}
  do
    echo "iteration $i, time:"
    RUST_LOG=sn_client cargo test --release -- --skip spent > ../../test-$i.log || true
  done

  cd -
}

nohup run_test_loop &

cleanup
