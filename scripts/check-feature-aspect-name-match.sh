#!/usr/bin/env bash
# check-feature-aspect-name-match.sh — enforce lesson 36:
# each file under modules/features/ must define an aspect whose name matches the filename.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

while IFS= read -r -d '' file; do
  basename="${file##*/}"
  # skip _ prefixed files (helpers/data)
  [[ "$basename" == _* ]] && continue
  feature_name="${basename%.nix}"

  # Extract all aspect names defined in this file
  mapfile -t aspect_names < <(grep -oP 'den\.aspects\.\K[a-zA-Z0-9_-]+(?=\s*=)' "$file" 2>/dev/null || true)

  if [[ ${#aspect_names[@]} -eq 0 ]]; then
    # File defines no aspect — skip (may be a helper that snuck in without _ prefix)
    continue
  fi

  # Expect exactly one match: the aspect name equals the file base name
  matched=0
  for name in "${aspect_names[@]}"; do
    if [[ "$name" == "$feature_name" ]]; then
      matched=1
      break
    fi
  done

  if [[ $matched -eq 0 ]]; then
    echo "[check-feature-aspect-name-match] FAIL: $file defines aspect(s) [${aspect_names[*]}] but filename is '$feature_name'" >&2
    fail=1
  fi
done < <(find modules/features -name '*.nix' -print0)

if [[ $fail -ne 0 ]]; then
  echo "[check-feature-aspect-name-match] one or more feature files have aspect name mismatches" >&2
  exit 1
fi

echo "[check-feature-aspect-name-match] ok"
