#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[tracked] not a git repository"
  exit 1
fi

untracked="$(git ls-files --others --exclude-standard)"

if [ -z "$untracked" ]; then
  echo "[tracked] ok: no untracked files"
  exit 0
fi

critical_untracked="$(
  printf '%s\n' "$untracked" | rg -n '^(flake\.nix|flake\.lock|hardware/.*\.nix|modules/.*\.nix|home/.*\.nix|pkgs/.*\.nix|scripts/.*\.sh|config/.*|files/.*)$' | cut -d: -f2- || true
)"

if [ -n "$critical_untracked" ]; then
  echo "[tracked] fail: critical untracked files (flakes can not see them):"
  printf '%s\n' "$critical_untracked"
  echo "[tracked] add them with: git add <file>"
  exit 1
fi

echo "[tracked] ok: no critical untracked files"
