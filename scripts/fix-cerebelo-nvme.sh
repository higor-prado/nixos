#!/usr/bin/env bash
set -euo pipefail

# Mount NVMe root
mkdir -p /tmp/nvme-root
sudo mount /dev/nvme0n1p2 /tmp/nvme-root

echo "=== extlinux.conf atual no NVMe ==="
cat /tmp/nvme-root/boot/extlinux/extlinux.conf

echo ""
echo "=== Kernels disponíveis no NVMe ==="
ls /tmp/nvme-root/boot/nixos/ | grep -E "^[a-z0-9]+-k-" | head -10
