#!/usr/bin/env bash

# shellcheck source=set_ops.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/set_ops.sh"

extc_check_set_sync() {
  local left_label="$1"
  local left_file="$2"
  local right_label="$3"
  local right_file="$4"
  local fail_fn="$5"

  local missing extra
  missing="$(set_missing_entries "$left_file" "$right_file")"
  extra="$(set_extra_entries "$left_file" "$right_file")"

  if [[ -n "$missing" ]]; then
    "$fail_fn" "${right_label} missing entries present in ${left_label}: $(tr '\n' ' ' <<<"$missing")"
  fi
  if [[ -n "$extra" ]]; then
    "$fail_fn" "${right_label} has entries not declared in ${left_label}: $(tr '\n' ' ' <<<"$extra")"
  fi
}

extc_require_pattern_in_file() {
  local pattern="$1"
  local file="$2"
  local message="$3"
  local fail_fn="$4"

  if ! rg -q "$pattern" "$file"; then
    "$fail_fn" "$message"
  fi
}

extc_check_host_defaults_contracts() {
  local fail_fn="$1"
  local -n host_dirs_ref="$2"
  local host host_file host_module_file

  for host in "${host_dirs_ref[@]}"; do
    host_file="hardware/${host}/default.nix"
    host_module_file="modules/hosts/${host}.nix"
    if [[ ! -f "$host_file" ]]; then
      "$fail_fn" "host '${host}' missing hardware/${host}/default.nix"
      continue
    fi
    if [[ ! -f "$host_module_file" ]]; then
      "$fail_fn" "host '${host}' missing modules/hosts/${host}.nix"
      continue
    fi

    local legacy_desktop_selector_pattern='custom\.desktop\.'
    legacy_desktop_selector_pattern+='profile[[:space:]]*='
    if rg -q "$legacy_desktop_selector_pattern" "$host_file"; then
      "$fail_fn" "host '${host}' default.nix must not declare a legacy desktop selector assignment"
    fi

    if rg -q '^[[:space:]]*environment\.systemPackages[[:space:]]*=' "$host_file"; then
      "$fail_fn" "host '${host}' default.nix must not define environment.systemPackages; use software profile/overrides and shared pack modules"
    fi

    if rg -q 'openssh\.authorizedKeys\.keys[[:space:]]*=' "$host_file"; then
      "$fail_fn" "host '${host}' default.nix must not track openssh.authorizedKeys.keys; move to untracked private overrides"
    fi

    if rg -q 'command[[:space:]]*=[[:space:]]*"ALL";' "$host_file" && rg -q 'NOPASSWD' "$host_file"; then
      "$fail_fn" "host '${host}' default.nix contains broad NOPASSWD ALL sudo policy; move to private least-privilege override"
    fi
  done
}
