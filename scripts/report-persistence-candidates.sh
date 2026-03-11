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
while IFS= read -r path; do
  [ -n "$path" ] || continue
  persisted["$path"]=1
done < <(
  {
    jq -r '.[] | if type == "string" then . else .directory end' "${tmp_json}.dirs"
    jq -r '.[] | if type == "string" then . else .file end' "${tmp_json}.files"
  } | sort -u
)

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

report_section() {
  local title="$1"
  shift
  local printed=0
  printf '## %s\n' "$title"
  while [ "$#" -gt 0 ]; do
    local path="$1"
    shift
    [ -e "$path" ] || continue
    is_persisted_path "$path" && continue
    is_store_symlink "$path" && continue
    local size
    size="$(path_size_kib "$path")"
    [ "$size" -gt 0 ] || continue
    printf '%8s KiB  %s\n' "$size" "$path"
    printed=1
  done
  if [ "$printed" -eq 0 ]; then
    printf '(none)\n'
  fi
  printf '\n'
}

report_section "Non-store-managed /etc candidates" \
  /etc/machine-id \
  /etc/NetworkManager/system-connections \
  /etc/ssh \
  /etc/adjtime

varlib_candidates=()
while IFS= read -r path; do
  case "$path" in
    /var/lib/AccountsService|/var/lib/NetworkManager|/var/lib/fwupd|/var/lib/upower|/var/lib/nixos)
      continue
      ;;
  esac
  varlib_candidates+=("$path")
done < <(find /var/lib -mindepth 1 -maxdepth 1 -printf '%p\n' 2>/dev/null | sort)

report_section "Top-level /var/lib candidates" "${varlib_candidates[@]}"

report_section "Writable root-owned candidates" \
  /root \
  /srv \
  /opt

log_ok "$scope" "reported candidate root-state paths for host '${host}' using persistence root '${persistence_root}'"
