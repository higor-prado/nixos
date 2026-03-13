#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmd "desktop-composition" "rg"

legacy_selector_pattern='custom\.desktop\.'
legacy_selector_pattern+='profile|custom\.desktop\.capabilities|desktop'
legacy_selector_pattern+='Profile'
matches="$(rg -n --glob '*.nix' "$legacy_selector_pattern" modules hardware || true)"

if [[ -n "$matches" ]]; then
  echo "[desktop-composition] fail: legacy desktop selector references found in active Nix code"
  printf '%s\n' "$matches"
  exit 1
fi

echo "[desktop-composition] ok: no legacy desktop selector references found in active Nix code"
