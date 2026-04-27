#!/usr/bin/env bash
set -euo pipefail

if makoctl mode | grep -q "do-not-disturb"; then
    makoctl mode -r do-not-disturb
else
    makoctl mode -a do-not-disturb
fi
