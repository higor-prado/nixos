#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Paths that usually indicate non-declarative runtime dependencies.
forbidden_regex='(/usr/local/bin|%h/\.local/bin|~\/\.local/bin|/home/[^"[:space:]]*/\.local/bin|%h/\.cargo/bin|~\/\.cargo/bin|/home/[^"[:space:]]*/\.cargo/bin)'

matches="$(
  rg -n --glob '*.nix' "$forbidden_regex" hardware modules pkgs 2>/dev/null || true
)"

if [ -n "$matches" ]; then
  echo "[paths] fail: non-declarative runtime paths found in nix files:"
  printf '%s\n' "$matches"
  exit 1
fi

echo "[paths] ok: no non-declarative runtime paths found in nix files"
