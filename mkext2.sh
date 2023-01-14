#!/bin/sh

loop=$(sudo losetup -f)
sudo losetup -P $loop $1
sudo mkfs.ext2 ${loop}p1
sudo losetup -d $loop
