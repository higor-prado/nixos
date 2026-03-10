#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

base_ref="${1:-origin/main}"

if ! git rev-parse --verify "$base_ref" >/dev/null 2>&1; then
  if git rev-parse --verify main >/dev/null 2>&1; then
    base_ref="main"
  else
    echo "[changed-quality] warn: base ref '$base_ref' not found; falling back to HEAD~1"
    base_ref="HEAD~1"
  fi
fi

merge_base="$(git merge-base HEAD "$base_ref" 2>/dev/null || true)"
if [ -z "$merge_base" ]; then
  echo "[changed-quality] warn: could not compute merge-base with '$base_ref'; falling back to HEAD~1"
  merge_base="HEAD~1"
fi

mapfile -t changed_files < <(git diff --name-only --diff-filter=ACMR "${merge_base}...HEAD")

if [ "${#changed_files[@]}" -eq 0 ]; then
  echo "[changed-quality] ok: no changed files against ${merge_base}"
  exit 0
fi

shell_files=()
nix_files=()

for file in "${changed_files[@]}"; do
  [ -f "$file" ] || continue
  case "$file" in
    *.sh) shell_files+=("$file") ;;
    *.nix) nix_files+=("$file") ;;
  esac
done

if [ "${#shell_files[@]}" -gt 0 ]; then
  echo "[changed-quality] shellcheck ${#shell_files[@]} changed shell files"
  shellcheck "${shell_files[@]}"
else
  echo "[changed-quality] no changed shell files"
fi

if [ "${#nix_files[@]}" -gt 0 ]; then
  echo "[changed-quality] parse-check ${#nix_files[@]} changed nix files"
  for file in "${nix_files[@]}"; do
    nix-instantiate --parse "$file" >/dev/null
  done
else
  echo "[changed-quality] no changed nix files"
fi

echo "[changed-quality] ok: changed-file quality checks passed"
