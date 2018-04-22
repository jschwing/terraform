#!/usr/bin/env bash

disk_path=$(readlink -f /dev/disk/by-id/google-persistent-disk-1)
mkfs.ext4 -F ${disk_path}
echo "${disk_path} /data ext4 defaults 0 0" >> /etc/fstab
awk '!a[$0]++' /etc/fstab > /etc/fstab
mount -a
