#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

checks=(
  'services\.resolved\.extraConfig|deprecated: use services.resolved.settings'
  'services\.resolved\.dnssec[[:space:]]*=|renamed: use services.resolved.settings.Resolve.DNSSEC'
  'services\.greetd\.vt[[:space:]]*=|deprecated: VT fixed to VT1'
  'xorg\.libxcb|renamed: use libxcb'
  'nixfmt-classic|deprecated: use nixfmt'
)

fail=0
for item in "${checks[@]}"; do
  pattern="${item%%|*}"
  note="${item#*|}"
  matches="$(rg -n --glob '*.nix' "$pattern" hardware modules home pkgs flake.nix 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    echo "[deprecations] fail: $note"
    printf '%s\n' "$matches"
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[deprecations] ok: no known deprecated patterns found in local nix files"
