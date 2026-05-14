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

# Create a fake interpreter symlink that satisfies is_host_nix_ld():
#   - symlink exists at $fake_interp
#   - readlink -f resolves to a path containing "nix-ld"
fake_interp_dir="$tmpdir/nix-ld"
mkdir -p "$fake_interp_dir"
touch "$fake_interp_dir/ld-linux-x86-64.so.2"
fake_interp="$tmpdir/fake-ld-linux"
ln -s "$fake_interp_dir/ld-linux-x86-64.so.2" "$fake_interp"

# Pre-flight: verify the fake interpreter satisfies is_host_nix_ld() logic.
# In some CI environments (e.g. Nix-installed runners), symlink resolution or
# environment propagation may behave differently.  Emit diagnostics on failure
# and skip the ELF scan tests rather than failing the whole gate.
if ! AUDIT_NIX_LD_INTERPRETER="$fake_interp" bash -c '
  interp="$AUDIT_NIX_LD_INTERPRETER"
  [[ -e "$interp" || -L "$interp" ]] || exit 1
  target="$(readlink -f -- "$interp" 2>/dev/null || true)"
  [[ -n "$target" ]] || exit 1
  [[ "$target" == *nix-ld* ]] || exit 1
'; then
  printf '[%s] DEBUG is_host_nix_ld pre-flight failed\n' "$scope"
  printf '[%s] DEBUG fake_interp=%s\n' "$scope" "$fake_interp"
  printf '[%s] DEBUG readlink -f:\n' "$scope"
  readlink -f -- "$fake_interp" 2>&1 || true
  printf '[%s] DEBUG ls -la:\n' "$scope"
  ls -la "$fake_interp" 2>&1 || true
  printf '[%s] DEBUG AUDIT_NIX_LD_INTERPRETER=%s\n' "$scope" "${AUDIT_NIX_LD_INTERPRETER:-<unset>}"
  log_warn "$scope" "SKIPPED: fake interpreter does not satisfy is_host_nix_ld in this environment"
  log_ok "$scope" "CLI checks passed (ELF fixture skipped)"
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
"$compiler" "$source_file" -Wl,--dynamic-linker="$fake_interp" -o "$matching_bin"
"$compiler" "$source_file" -Wl,--dynamic-linker=/not-the-nix-ld-fixture -o "$negative_bin"

# Test 1: matching binary is found
scan_out="$tmpdir/scan.out"
HOME="$fixture_home" \
  XDG_DATA_HOME="$fixture_home/.local/share" \
  XDG_CONFIG_HOME="$fixture_home/.config" \
  XDG_CACHE_HOME="$fixture_home/.cache" \
  AUDIT_NIX_LD_INTERPRETER="$fake_interp" \
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
  AUDIT_NIX_LD_INTERPRETER="$fake_interp" \
  run_expect 0 "$ignore_out"
assert_not_contains "~/.local/share/matching" "$ignore_out"

log_ok "$scope" "fixture checks passed"
