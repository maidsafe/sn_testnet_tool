#!/bin/bash

# https://betterdev.blog/minimal-safe-bash-script-template/
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

export TMPDIR=~/tests

count=0
cat ./tests/index | while read line; do

  type=$(echo $line | awk '{print $1}')
  url=$(echo $line | awk '{print $2}')
  printf "\n==> Getting a $type file from $url \n"
  printf "\n...................\n\n"

  printf "safe cat-ting..."
  count=$((count+1))
  cd $TMPDIR
  time safe cat $url > "$TMPDIR/$count.$type"
  printf "\n................... \n\n"
  filesize=$(ls -lh $TMPDIR/$count.$type  | awk '{print  $5}')
  printf "File downloaded to ==> $TMPDIR/$count.$type \n\n"
  printf "File size is ==> $filesize \n\n"

  printf "...................\n\n"
  
done

wait

cleanup
