#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
enter_repo_root "${BASH_SOURCE[0]}"

scope="persist-candidates"
host="${1:-predator}"
persistence_root="${2:-/persist}"

require_cmds "$scope" nix jq du find readlink sort

tmp_json="$(mktemp_file_scoped "$scope")"
trap 'rm -f "$tmp_json"' EXIT

nix eval --json --file "${REPO_ROOT}/hardware/${host}/_persistence-inventory.nix" directories >"${tmp_json}.dirs"
nix eval --json --file "${REPO_ROOT}/hardware/${host}/_persistence-inventory.nix" files >"${tmp_json}.files"

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
reset="$(color '0')"

is_persisted_path() {
  local path="$1"
  [ -n "${persisted[$path]:-}" ]
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
  printf '%b[%s]%b %8s KiB  %s\n' "$color_prefix" "$status" "$reset" "$size" "$path"
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
  local printed=0
  local path
  printf '## Declared persisted inventory\n'
  for path in "${persisted_paths[@]}"; do
    local size="0"
    if [ -e "$path" ] && ! is_store_symlink "$path"; then
      size="$(path_size_kib "$path")"
    fi
    print_status_line "declared  " "$blue" "$size" "$path"
    printed=1
  done
  if [ "$printed" -eq 0 ]; then
    printf '(none)\n'
  fi
  printf '\n'
}

report_unlisted_declared() {
  local -n listed_paths_ref=$1
  local printed=0
  local path
  printf '## Declared paths outside default candidate scan\n'
  for path in "${persisted_paths[@]}"; do
    if [ -n "${listed_paths_ref[$path]:-}" ]; then
      continue
    fi
    local size="0"
    if [ -e "$path" ] && ! is_store_symlink "$path"; then
      size="$(path_size_kib "$path")"
    fi
    print_status_line "declared  " "$blue" "$size" "$path"
    printed=1
  done
  if [ "$printed" -eq 0 ]; then
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

etc_candidates=(
  /etc/machine-id \
  /etc/NetworkManager/system-connections \
  /etc/ssh \
  /etc/adjtime
)
record_listed_paths "${etc_candidates[@]}"

report_declared_inventory

report_candidate_section "Non-store-managed /etc candidates" "${etc_candidates[@]}"

varlib_candidates=()
while IFS= read -r path; do
  case "$path" in
    /var/lib/AccountsService|/var/lib/NetworkManager|/var/lib/fwupd|/var/lib/upower|/var/lib/nixos)
      continue
      ;;
  esac
  varlib_candidates+=("$path")
done < <(find /var/lib -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null | sort)
record_listed_paths "${varlib_candidates[@]}"

report_candidate_section "Top-level /var/lib candidates" "${varlib_candidates[@]}"

root_owned_candidates=(
  /root \
  /srv \
  /opt
)
record_listed_paths "${root_owned_candidates[@]}"

report_candidate_section "Writable root-owned candidates" "${root_owned_candidates[@]}"

report_unlisted_declared listed_candidate_paths

log_ok "$scope" "reported candidate root-state paths for host '${host}' using persistence root '${persistence_root}'"
