#!/bin/sh
# Copies the bootloader (and kernel) to the first partition of disk

loop=$(sudo losetup -f)
sudo losetup -P $loop $1
mkdir tmp
sudo mount ${loop}p1 tmp
sudo cp $2 tmp/
sudo sync
sudo umount tmp
sudo losetup -d $loop
rmdir tmp
