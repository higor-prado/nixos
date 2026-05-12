#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
cd "$REPO_ROOT" || exit 1

scope="audit-nix-ld-usage-fixture-test"
script="$REPO_ROOT/scripts/audit-nix-ld-usage.sh"
tmpdir="$(mktemp_dir_scoped audit-nix-ld-usage-fixture-test)"
trap 'rm -rf "$tmpdir"' EXIT

run_expect() {
  local expected_code="$1" out_file="$2"
  shift 2

  set +e
  "$script" "$@" >"$out_file" 2>&1
  local code=$?
  set -e

  if [[ "$code" -ne "$expected_code" ]]; then
    log_fail "$scope" "expected exit $expected_code, got $code: $*"
    sed -n '1,200p' "$out_file" >&2 || true
    exit 1
  fi
}

assert_contains() {
  local needle="$1" file="$2"
  if [[ "$(<"$file")" != *"$needle"* ]]; then
    log_fail "$scope" "missing expected output: $needle"
    sed -n '1,200p' "$file" >&2 || true
    exit 1
  fi
}

assert_not_contains() {
  local needle="$1" file="$2"
  if [[ "$(<"$file")" == *"$needle"* ]]; then
    log_fail "$scope" "unexpected output: $needle"
    sed -n '1,200p' "$file" >&2 || true
    exit 1
  fi
}

# CLI tests
help_out="$tmpdir/help.out"
run_expect 0 "$help_out" --help
assert_contains "use nix-ld" "$help_out"

unknown_out="$tmpdir/unknown.out"
run_expect 2 "$unknown_out" --definitely-not-an-option

# Compiler-based fixture tests
compiler=""
if command -v cc >/dev/null 2>&1; then compiler="cc"
elif command -v gcc >/dev/null 2>&1; then compiler="gcc"
fi

if [[ -z "$compiler" ]]; then
  log_warn "$scope" "SKIPPED: no C compiler available for ELF fixture checks"
  log_ok "$scope" "CLI checks passed"
  exit 0
fi

source_file="$tmpdir/minimal.c"
cat >"$source_file" <<'EOF'
int main(void) { return 0; }
EOF

fixture_home="$tmpdir/home"
mkdir -p "$fixture_home"

matching_bin="$fixture_home/.local/share/matching/bin/matching"
negative_bin="$fixture_home/.local/share/neg/bin/not-matching"
mkdir -p "$(dirname "$matching_bin")" "$(dirname "$negative_bin")"
"$compiler" "$source_file" -Wl,--dynamic-linker=/lib64/ld-linux-x86-64.so.2 -o "$matching_bin"
"$compiler" "$source_file" -Wl,--dynamic-linker=/not-the-nix-ld-fixture -o "$negative_bin"

# Test 1: matching binary is found
scan_out="$tmpdir/scan.out"
HOME="$fixture_home" \
  XDG_DATA_HOME="$fixture_home/.local/share" \
  XDG_CONFIG_HOME="$fixture_home/.config" \
  XDG_CACHE_HOME="$fixture_home/.cache" \
  run_expect 0 "$scan_out"
# Path is shortened to ~ because it's under $HOME
assert_contains "~/.local/share/matching/bin/matching" "$scan_out"
assert_not_contains "$negative_bin" "$scan_out"
assert_contains "matching" "$scan_out"

# Test 2: ignored paths are skipped
ignore_file="$REPO_ROOT/private/audit-nix-ld-usage-ignored.txt"
if [[ -f "$ignore_file" ]]; then
  mv "$ignore_file" "${ignore_file}.bak"
  trap 'rm -rf "$tmpdir"; mv "${ignore_file}.bak" "$ignore_file"' EXIT
else
  trap 'rm -rf "$tmpdir"; rm -f "$ignore_file"' EXIT
fi
printf '%s\n' "$fixture_home/.local/share/matching" > "$ignore_file"
ignore_out="$tmpdir/ignore.out"
HOME="$fixture_home" \
  XDG_DATA_HOME="$fixture_home/.local/share" \
  run_expect 0 "$ignore_out"
assert_not_contains "~/.local/share/matching" "$ignore_out"

log_ok "$scope" "fixture checks passed"
