#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
SCRIPT_DIR="$(script_dir "${BASH_SOURCE[0]}")"
enter_repo_root "${BASH_SOURCE[0]}"
ALLOWLIST="$SCRIPT_DIR/public-safety-allowlist.txt"
ARTIFACT_DIR="${PUBLIC_SAFETY_ARTIFACT_DIR:-${TMPDIR:-/tmp}/nixos-public-safety}"
PUBLIC_USER_NAME="${PUBLIC_USER_NAME:-$(id -un)}"

if ! mkdir -p "$ARTIFACT_DIR" 2>/dev/null; then
  ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nixos-public-safety-XXXXXX")"
fi

if [ ! -w "$ARTIFACT_DIR" ]; then
  ARTIFACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nixos-public-safety-XXXXXX")"
fi

TOTAL_FAILS=0

run_scan() {
  local name="$1"
  local pattern="$2"
  local raw_file="$ARTIFACT_DIR/${name}.raw.txt"
  local filt_file="$ARTIFACT_DIR/${name}.filtered.txt"

  (
    cd "$REPO_ROOT"
    rg -n --no-heading --hidden \
      --glob '!.git/**' \
      --glob '!reports/**' \
      "$pattern" . >"$raw_file" || true
  )

  if [ -f "$ALLOWLIST" ] && [ -s "$ALLOWLIST" ]; then
    grep -Evf "$ALLOWLIST" "$raw_file" >"$filt_file" || true
  else
    cp "$raw_file" "$filt_file"
  fi

  local count
  count=$(wc -l <"$filt_file")
  echo "${name}=${count}"
  if [ "$count" -gt 0 ]; then
    TOTAL_FAILS=$((TOTAL_FAILS + count))
  fi
}

run_scan "local_file_flake_urls" 'git\+file:///|file:///home/'
run_scan "absolute_home_paths" "(^|[[:space:]=:\"])\\/home\\/${PUBLIC_USER_NAME}([/\"]|$)"
run_scan "private_ipv4" '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3})\b'
run_scan "private_emails" '[A-Za-z0-9._%+-]+@gmail\.com'
run_scan "high_confidence_tokens" 'AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}|sk-[A-Za-z0-9]{20,}|Bearer[[:space:]]+[A-Za-z0-9._-]{20,}|BEGIN[[:space:]]+[A-Z ]*PRIVATE KEY'

if [ "$TOTAL_FAILS" -gt 0 ]; then
  echo "FAIL: public safety checks found ${TOTAL_FAILS} unallowlisted matches."
  exit 1
fi

echo "PASS: public safety checks found no unallowlisted matches."
