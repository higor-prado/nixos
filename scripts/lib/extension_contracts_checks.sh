#!/usr/bin/env bash

# shellcheck source=set_ops.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/set_ops.sh"

extc_is_allowed_host_role_assignment() {
  local file="$1"
  [[ "$file" == "modules/features/core-options.nix" ]] || [[ "$file" == hardware/*/default.nix ]]
}

extc_check_assignment_scope() {
  local label="$1"
  local pattern="$2"
  local checker="$3"
  local fail_fn="$4"
  local line file

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    file="${line%%:*}"
    if ! "$checker" "$file"; then
      "$fail_fn" "${label} assignment outside contract: ${line}"
    fi
  done < <(rg -n --glob '*.nix' "$pattern" hardware modules flake.nix || true)
}

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

extc_check_host_descriptor_matches_defaults() {
  local fail_fn="$1"
  local -n host_dirs_ref="$2"
  local host runtime_role host_file host_module_file

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

    runtime_role="$(extc_host_runtime_role "${host}" 2>/dev/null || true)"

    if [[ -z "$runtime_role" ]]; then
      "$fail_fn" "host '${host}' must expose a runtime custom.host.role"
    elif ! rg -q "custom\\.host\\.role = \"${runtime_role}\";" "$host_file"; then
      "$fail_fn" "host '${host}' default.nix must set custom.host.role = \"${runtime_role}\""
    fi

    if extc_host_descriptor_has_legacy_desktop_selector "$host" 2>/dev/null; then
      "$fail_fn" "host '${host}' descriptor must not declare a legacy desktop selector field"
    fi

    local legacy_desktop_selector_pattern='custom\.desktop\.'
    legacy_desktop_selector_pattern+='profile[[:space:]]*='
    if rg -q "$legacy_desktop_selector_pattern" "$host_file"; then
      "$fail_fn" "host '${host}' default.nix must not declare a legacy desktop selector assignment"
    fi

    if [[ "$runtime_role" == "desktop" ]]; then
      if ! rg -q 'desktop-[a-z0-9-]+' "$host_module_file"; then
        "$fail_fn" "desktop host '${host}' modules/hosts/${host}.nix must include a desktop-* composition aspect"
      fi
    fi

    if ! rg -q 'users\.[A-Za-z0-9_-]+(\.classes)?[[:space:]]*=' "$host_module_file"; then
      "$fail_fn" "host '${host}' modules/hosts/${host}.nix must declare at least one tracked host user under den.hosts.<system>.${host}.users"
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
