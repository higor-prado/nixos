#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

require_cmd "option-boundary" "rg"

allow_prefixes=(
  "modules/options/"
  "modules/features/"
)

is_allowed() {
  local candidate="$1"
  local prefix
  for prefix in "${allow_prefixes[@]}"; do
    if [[ "$candidate" == "$prefix"* ]]; then
      return 0
    fi
  done
  return 1
}

matches="$(rg -n --glob '*.nix' '^\s*options\.' modules home || true)"

if [[ -z "$matches" ]]; then
  echo "[option-boundary] ok: no option declarations found"
  exit 0
fi

violations=""
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  file="${line%%:*}"
  if ! is_allowed "$file"; then
    violations+="$line"$'\n'
  fi
done <<<"$matches"

if [[ -n "$violations" ]]; then
  echo "[option-boundary] fail: option declarations found outside allowed option modules"
  printf '%s' "$violations"
  exit 1
fi

echo "[option-boundary] ok: option declarations limited to option modules"
