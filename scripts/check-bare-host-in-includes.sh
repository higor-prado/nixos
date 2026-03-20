#!/usr/bin/env bash
# check-bare-host-in-includes.sh — gate against bare `{ host }:` lambdas in
# active modules. In the dendritic runtime, host data should flow through
# `config.repo.context.*` inside published lower-level modules, not through
# ad hoc host-lambda wiring hidden in module lists.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

while IFS= read -r -d '' file; do
  # Find lines with a bare host-lambda opener: ( { host followed by , whitespace or }
  # Exclude comment lines.
  results=$(
    grep -Pn '\(\s*\{\s*host[,\s}]' "$file" 2>/dev/null \
    | grep -v '^\s*[0-9]*:.*#' \
    || true
  )
  if [[ -n "$results" ]]; then
    echo "[check-bare-host-in-includes] FAIL: $file" >&2
    echo "$results" >&2
    fail=1
  fi
done < <(find modules/ -name '*.nix' -print0)

if [[ $fail -ne 0 ]]; then
  echo "[check-bare-host-in-includes] bare host lambdas found — publish lower-level modules and read host data through repo.context instead" >&2
  exit 1
fi

echo "[check-bare-host-in-includes] ok"
