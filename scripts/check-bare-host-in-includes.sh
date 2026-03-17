#!/usr/bin/env bash
# check-bare-host-in-includes.sh — gate against bare {host}: / {host,...}: lambdas
# in includes without a den.lib wrapper. Under den._.bidirectional these fire in
# both the host and host+user pipelines, silently duplicating NixOS config.
# Correct patterns: den.lib.perHost, den.lib.perUser, den.lib.take.*, den.lib.parametric.
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

while IFS= read -r -d '' file; do
  # Find lines with a bare host-lambda opener: ( { host followed by , whitespace or }
  # Exclude comment lines and lines that already have a den.lib wrapper on the same line.
  results=$(
    grep -Pn '\(\s*\{\s*host[,\s}]' "$file" 2>/dev/null \
    | grep -v '^\s*[0-9]*:.*#' \
    | grep -vP 'den\.lib\.(perHost|perUser|take|parametric)' \
    || true
  )
  if [[ -n "$results" ]]; then
    echo "[check-bare-host-in-includes] FAIL: $file" >&2
    echo "$results" >&2
    fail=1
  fi
done < <(find modules/ -name '*.nix' -print0)

if [[ $fail -ne 0 ]]; then
  echo "[check-bare-host-in-includes] bare host lambdas in includes — wrap with den.lib.perHost / den.lib.perUser" >&2
  exit 1
fi

echo "[check-bare-host-in-includes] ok"
