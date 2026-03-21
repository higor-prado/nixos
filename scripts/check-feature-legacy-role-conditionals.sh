#!/usr/bin/env bash
# check-feature-legacy-role-conditionals.sh — forbid reintroducing the removed
# legacy role-selector pattern inside feature modules. Feature inclusion in host
# composition is the condition; `mkIf custom.host.role` is dead architecture.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

results="$(
  grep -rn 'mkIf.*custom\.host\.role\|custom\.host\.role.*mkIf' modules/features/ \
    2>/dev/null || true
)"

if [[ -n "$results" ]]; then
  echo "[check-feature-legacy-role-conditionals] FAIL: legacy role-selector conditional found in modules/features/ — use explicit host composition instead" >&2
  echo "$results" >&2
  exit 1
fi

echo "[check-feature-legacy-role-conditionals] ok"
