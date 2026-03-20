#!/usr/bin/env bash
# check-feature-aspect-name-match.sh — enforce that each feature file publishes
# lower-level modules whose name matches the filename.
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

  # Extract published lower-level module names from either direct
  # `flake.modules.<class>.<name> =` form or grouped `flake.modules = { <class>.<name> = ...; }`.
  mapfile -t published_names < <(
    grep -oP 'flake\.modules\.(?:nixos|homeManager)\.\K[a-zA-Z0-9_-]+(?=\s*=)|(?<!flake\.modules\.)\b(?:nixos|homeManager)\.\K[a-zA-Z0-9_-]+(?=\s*=)' "$file" \
      2>/dev/null \
      | sort -u \
      || true
  )

  if [[ ${#published_names[@]} -eq 0 ]]; then
    # File defines no lower-level module publisher — skip.
    continue
  fi

  # Expect at least one published name to match the filename.
  matched=0
  for name in "${published_names[@]}"; do
    if [[ "$name" == "$feature_name" ]]; then
      matched=1
      break
    fi
  done

  if [[ $matched -eq 0 ]]; then
    echo "[check-feature-aspect-name-match] FAIL: $file publishes [${published_names[*]}] but filename is '$feature_name'" >&2
    fail=1
  fi
done < <(find modules/features -name '*.nix' -print0)

if [[ $fail -ne 0 ]]; then
  echo "[check-feature-aspect-name-match] one or more feature files have publisher name mismatches" >&2
  exit 1
fi

echo "[check-feature-aspect-name-match] ok"
