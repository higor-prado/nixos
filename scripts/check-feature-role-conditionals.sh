#!/usr/bin/env bash
# check-feature-role-conditionals.sh — enforce lesson 13 + 003-module-ownership.md:
# mkIf custom.host.role is forbidden inside modules/features/. Feature inclusion
# IS the condition; role guards inside features are a design smell and bypass
# the host-composition model.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

results=$(
  grep -rn 'mkIf.*custom\.host\.role\|custom\.host\.role.*mkIf' modules/features/ \
    2>/dev/null || true
)

if [[ -n "$results" ]]; then
  echo "[check-feature-role-conditionals] FAIL: mkIf custom.host.role found in modules/features/ — use host composition instead" >&2
  echo "$results" >&2
  exit 1
fi

echo "[check-feature-role-conditionals] ok"
