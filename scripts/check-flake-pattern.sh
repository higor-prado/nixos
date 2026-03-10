#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

fail=0

report_fail() {
  log_fail "flake-pattern" "$1"
  fail=1
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

inputs_file="$tmp_dir/inputs.txt"
source_inputs_file="$tmp_dir/source-inputs.txt"

# Collect top-level input keys from flake.nix (ignore dotted nested assignments).
awk '
  /inputs = \{/ { in_inputs = 1; depth = 1; next }
  in_inputs {
    opens = gsub(/\{/, "{")
    closes = gsub(/\}/, "}")
    if (depth == 1 && match($0, /^[[:space:]]*([A-Za-z0-9._-]+)[[:space:]]*=/, m)) {
      key = m[1]
      if (index(key, ".") == 0) print key
    }
    depth += opens - closes
    if (depth == 0) exit
  }
' flake.nix | sort -u >"$inputs_file"

# Detect non-kebab-case input names.
while IFS= read -r key; do
  if [[ ! "$key" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    report_fail "input '$key' is not kebab-case"
  fi
done <"$inputs_file"

# Collect inputs that are declared as flake = false.
awk '
  /inputs = \{/ { in_inputs = 1; depth = 1; next }
  in_inputs {
    if (depth == 1 && match($0, /^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=[[:space:]]*[{]/, m)) {
      current = m[1]
      current_depth = 1
      next
    }
    if (current != "") {
      opens = gsub(/\{/, "{")
      closes = gsub(/\}/, "}")
      current_depth += opens - closes
      if ($0 ~ /flake[[:space:]]*=[[:space:]]*false[[:space:]]*;/) print current
      if (current_depth == 0) current = ""
    }
    opens2 = gsub(/\{/, "{")
    closes2 = gsub(/\}/, "}")
    depth += opens2 - closes2
    if (depth == 0) exit
  }
' flake.nix | sort -u >"$source_inputs_file"

while IFS= read -r key; do
  [ -z "$key" ] && continue
  if [[ ! "$key" =~ -src$ ]]; then
    report_fail "source input '$key' should end with '-src'"
  fi
done <"$source_inputs_file"

# Ensure no inline anonymous module blocks remain in flake modules list.
if awk '
  /modules[[:space:]]*=[[:space:]]*\[/ { in_modules = 1 }
  in_modules && /^[[:space:]]*\{[[:space:]]*$/ { found = 1 }
  in_modules && /\][[:space:]]*;/ { in_modules = 0 }
  END { exit(found ? 0 : 1) }
' flake.nix; then
  report_fail "inline anonymous module blocks found in flake.nix modules list"
fi

# Enforce system accessor consistency.
pkgs_system_count="$( (rg -n --pcre2 'pkgs\.system(?![A-Za-z0-9_])' -g '*.nix' . || true) | wc -l | tr -d ' ' )"
host_system_count="$( (rg -n 'pkgs\.stdenv\.hostPlatform\.system' -g '*.nix' . || true) | wc -l | tr -d ' ' )"

if [ "$pkgs_system_count" -gt 0 ]; then
  report_fail "found deprecated pkgs.system accessor usage ($pkgs_system_count matches)"
fi

if [ "$host_system_count" -eq 0 ]; then
  report_fail "no pkgs.stdenv.hostPlatform.system usage found"
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[flake-pattern] ok: flake input naming and wiring patterns match policy"
