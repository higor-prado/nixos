#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
cd "$REPO_ROOT" || exit 1

scope="gate-cli-contracts-test"
tmpdir="$(mktemp_dir_scoped gate-cli-contracts-test)"
trap 'rm -rf "$tmpdir"' EXIT

run_and_capture() {
  local name="$1"
  shift
  set +e
  "$@" >"$tmpdir/${name}.out" 2>&1
  local exit_code=$?
  set -e
  printf '%s' "$exit_code"
}

assert_exit_code() {
  local got="$1"
  local expected="$2"
  local label="$3"
  if [[ "$got" != "$expected" ]]; then
    log_fail "$scope" "${label}: expected exit ${expected}, got ${got}"
    exit 1
  fi
}

assert_output_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -q --fixed-strings "$pattern" "$file"; then
    log_fail "$scope" "${label}: missing expected output pattern: ${pattern}"
    log_warn "$scope" "captured output (${file}):"
    sed -n '1,200p' "$file" >&2 || true
    exit 1
  fi
}

ec="$(run_and_capture run_validation_help ./scripts/run-validation-gates.sh --help)"
assert_exit_code "$ec" "0" "run-validation --help"
assert_output_contains "$tmpdir/run_validation_help.out" "Usage: scripts/run-validation-gates.sh" "run-validation --help"

ec="$(run_and_capture run_validation_invalid ./scripts/run-validation-gates.sh invalid-stage)"
assert_exit_code "$ec" "1" "run-validation invalid stage"
assert_output_contains "$tmpdir/run_validation_invalid.out" "[validation-gates] unknown stage: invalid-stage" "run-validation invalid stage"

ec="$(run_and_capture runtime_smoke_help ./scripts/check-runtime-smoke.sh --help)"
assert_exit_code "$ec" "0" "runtime-smoke --help"
assert_output_contains "$tmpdir/runtime_smoke_help.out" "Usage:" "runtime-smoke --help"

ec="$(run_and_capture runtime_smoke_invalid ./scripts/check-runtime-smoke.sh --not-a-real-flag)"
assert_exit_code "$ec" "2" "runtime-smoke invalid arg"
assert_output_contains "$tmpdir/runtime_smoke_invalid.out" "[runtime-smoke] fail: unknown argument: --not-a-real-flag" "runtime-smoke invalid arg"

ec="$(run_and_capture extension_contracts_default ./scripts/check-extension-contracts.sh)"
assert_exit_code "$ec" "0" "extension-contracts default run"
assert_output_contains "$tmpdir/extension_contracts_default.out" "[extension-contracts] ok: host/composition extension contracts hold" "extension-contracts default run"

ec="$(run_and_capture extension_contracts_help ./scripts/check-extension-contracts.sh --help)"
assert_exit_code "$ec" "0" "extension-contracts --help"
assert_output_contains "$tmpdir/extension_contracts_help.out" "Usage:" "extension-contracts --help"

ec="$(run_and_capture extension_contracts_invalid ./scripts/check-extension-contracts.sh --not-a-real-flag)"
assert_exit_code "$ec" "2" "extension-contracts invalid arg"
assert_output_contains "$tmpdir/extension_contracts_invalid.out" "[extension-contracts] fail: unknown argument: --not-a-real-flag" "extension-contracts invalid arg"

log_ok "$scope" "CLI/contract tests passed"
