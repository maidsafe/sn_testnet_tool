#!/usr/bin/env bash

block_device=$1
if [[ -z "$block_device" ]]; then
    echo "A value for the block device must be supplied."
    exit 1
fi

function format_disk() {
    n="1"
    formatted_block_device="$block_device$n"
    blkid_output=$(blkid -o list)
    if [[ "$blkid_output" != *"$formatted_block_device"* ]]; then
        echo -e "n\np\n1\n\n\nw\n" | fdisk "$block_device"
    fi
}

function create_filesystem() {
    blkid_output=$(blkid "$formatted_block_device")
    if [[ "$blkid_output" == "$formatted_block_device: PARTUUID"* ]]; then
        mkfs.ext4 "$formatted_block_device"
    fi
}

format_disk
create_filesystem
