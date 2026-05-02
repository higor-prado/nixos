#!/usr/bin/env bash
set -euo pipefail
trap 'sudo umount /tmp/sd-boot 2>/dev/null || true' EXIT

mkdir -p /tmp/sd-boot
sudo mount /dev/mmcblk0p1 /tmp/sd-boot
echo "=== extlinux.conf ==="
find /tmp/sd-boot -name "extlinux.conf" -exec cat {} \;
sudo umount /tmp/sd-boot
