#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

count=0
for line in $(<./tests/indexxx xargs); do
      printf "  ===================== \n"
      printf "safe cat-ting $line"
      count=$((count+1))
      cd $TMPDIR
      time safe cat $line > "$TMPDIR/$count.jpg"
      printf "\n dlded ==> $TMPDIR/$count.jpg \n\n"
done


wait

cleanup