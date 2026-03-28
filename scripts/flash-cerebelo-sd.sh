#!/usr/bin/env bash
set -euo pipefail

IMAGE="$HOME/Downloads/orangepi5-sd-image.img.zst"
DEVICE="/dev/mmcblk0"

echo "[flash] Writing $IMAGE to $DEVICE ..."
sudo zstdcat "$IMAGE" | sudo dd of="$DEVICE" bs=4M status=progress oflag=sync
echo "[flash] Done. SD card ready."
