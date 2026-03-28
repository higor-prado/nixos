#!/usr/bin/env bash
set -euo pipefail

mkdir -p /tmp/sd-boot
sudo mount /dev/mmcblk0p1 /tmp/sd-boot
echo "=== extlinux.conf ==="
find /tmp/sd-boot -name "extlinux.conf" -exec cat {} \;
sudo umount /tmp/sd-boot
