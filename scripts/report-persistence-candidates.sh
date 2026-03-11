#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

scope="persist-candidates"
host="${1:-predator}"
persistence_root="${2:-/persist}"
inventory_file="${PERSISTENCE_INVENTORY_FILE:-${REPO_ROOT}/hardware/${host}/_persistence-inventory.nix}"
etc_root="${PERSISTENCE_ETC_ROOT:-/etc}"
var_lib_root="${PERSISTENCE_VAR_LIB_ROOT:-/var/lib}"
root_owned_candidate_list="${PERSISTENCE_ROOT_OWNED_CANDIDATES:-/root /srv /opt}"

require_cmds "$scope" nix jq du find readlink sort

tmp_json="$(mktemp_file_scoped "$scope")"
trap 'rm -f "$tmp_json"' EXIT

nix eval --json --file "${inventory_file}" directories >"${tmp_json}.dirs"
nix eval --json --file "${inventory_file}" files >"${tmp_json}.files"

declare -A persisted=()
declare -a persisted_paths=()
while IFS= read -r path; do
  [ -n "$path" ] || continue
  persisted["$path"]=1
  persisted_paths+=("$path")
done < <(
  {
    jq -r '.[] | if type == "string" then . else .directory end' "${tmp_json}.dirs"
    jq -r '.[] | if type == "string" then . else .file end' "${tmp_json}.files"
  } | sort -u
)

use_color=0
if [ -t 1 ] && [ "${NO_COLOR:-}" != "1" ]; then
  use_color=1
fi

color() {
  local code="$1"
  if [ "$use_color" -eq 1 ]; then
    printf '\033[%sm' "$code"
  fi
}

green="$(color '32')"
yellow="$(color '33')"
blue="$(color '34')"
cyan="$(color '36')"
reset="$(color '0')"

is_persisted_path() {
  local path="$1"
  [ -n "${persisted[$path]:-}" ]
}

has_persisted_descendant() {
  local path="$1"
  local persisted_path
  for persisted_path in "${persisted_paths[@]}"; do
    case "$persisted_path" in
      "$path"/*)
        return 0
        ;;
    esac
  done
  return 1
}

is_store_symlink() {
  local path="$1"
  [ -L "$path" ] || return 1
  local target
  target="$(readlink -f "$path" 2>/dev/null || true)"
  [[ "$target" == /nix/store/* ]]
}

path_size_kib() {
  local size
  size="$(du -sk "$1" 2>/dev/null | awk 'NR==1 { print $1 }')"
  printf '%s\n' "${size:-0}"
}

print_status_line() {
  local status="$1"
  local color_prefix="$2"
  local size="$3"
  local path="$4"
  printf '%b[%-10s]%b %8s KiB  %s\n' "$color_prefix" "$status" "$reset" "$size" "$path"
}

report_candidate_section() {
  local title="$1"
  shift
  local printed=0
  printf '## %s\n' "$title"
  while [ "$#" -gt 0 ]; do
    local path="$1"
    shift
    [ -e "$path" ] || continue
    is_store_symlink "$path" && continue
    local size
    size="$(path_size_kib "$path")"
    [ "$size" -gt 0 ] || continue
    if is_persisted_path "$path"; then
      print_status_line "persisted" "$green" "$size" "$path"
    elif has_persisted_descendant "$path"; then
      print_status_line "children " "$cyan" "$size" "$path"
    else
      print_status_line "candidate " "$yellow" "$size" "$path"
    fi
    printed=1
  done
  if [ "$printed" -eq 0 ]; then
    printf '(none)\n'
  fi
  printf '\n'
}

report_declared_inventory() {
  local -n listed_paths_ref=$1
  local path
  local printed_inside=0
  local printed_outside=0
  printf '## Declared persisted inventory\n'
  printf '### Inside default candidate scan\n'
  for path in "${persisted_paths[@]}"; do
    if [ -z "${listed_paths_ref[$path]:-}" ]; then
      continue
    fi
    local size="0"
    if [ -e "$path" ] && ! is_store_symlink "$path"; then
      size="$(path_size_kib "$path")"
    fi
    print_status_line "declared" "$blue" "$size" "$path"
    printed_inside=1
  done
  if [ "$printed_inside" -eq 0 ]; then
    printf '(none)\n'
  fi
  printf '\n'

  printf '### Outside default candidate scan\n'
  for path in "${persisted_paths[@]}"; do
    if [ -n "${listed_paths_ref[$path]:-}" ]; then
      continue
    fi
    local size="0"
    if [ -e "$path" ] && ! is_store_symlink "$path"; then
      size="$(path_size_kib "$path")"
    fi
    print_status_line "declared" "$blue" "$size" "$path"
    printed_outside=1
  done
  if [ "$printed_outside" -eq 0 ]; then
    printf '(none)\n'
  fi
  printf '\n'
}

declare -A listed_candidate_paths=()
record_listed_paths() {
  local path
  for path in "$@"; do
    # shellcheck disable=SC2034
    listed_candidate_paths["$path"]=1
  done
}

printf 'Legend:\n'
print_status_line "declared  " "$blue" "-" "in inventory"
print_status_line "persisted " "$green" "-" "candidate path itself is declared"
print_status_line "children  " "$cyan" "-" "child paths are declared"
print_status_line "candidate " "$yellow" "-" "not declared"
printf '\n'

etc_candidates=(
  "${etc_root}/machine-id" \
  "${etc_root}/NetworkManager/system-connections" \
  "${etc_root}/ssh" \
  "${etc_root}/adjtime"
)
record_listed_paths "${etc_candidates[@]}"

report_declared_inventory listed_candidate_paths

report_candidate_section "Non-store-managed /etc candidates" "${etc_candidates[@]}"

varlib_candidates=()
while IFS= read -r path; do
  case "$path" in
    "${var_lib_root}/AccountsService"|\
    "${var_lib_root}/NetworkManager"|\
    "${var_lib_root}/fwupd"|\
    "${var_lib_root}/upower"|\
    "${var_lib_root}/nixos")
      continue
      ;;
  esac
  varlib_candidates+=("$path")
done < <(find "${var_lib_root}" -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null | sort)
record_listed_paths "${varlib_candidates[@]}"

report_candidate_section "Top-level /var/lib candidates" "${varlib_candidates[@]}"

read -r -a root_owned_candidates <<<"${root_owned_candidate_list}"
record_listed_paths "${root_owned_candidates[@]}"

report_candidate_section "Writable root-owned candidates" "${root_owned_candidates[@]}"

log_ok "$scope" "reported candidate root-state paths for host '${host}' using persistence root '${persistence_root}'"
