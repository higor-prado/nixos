#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=../../scripts/lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/common.sh"
# shellcheck source=../../scripts/lib/runtime_warning_budget.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/../../scripts/lib/runtime_warning_budget.sh"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
export REPO_ROOT
cd "$REPO_ROOT" || exit 1

scope="runtime-warning-budget-lib-test"
tmpdir="$(mktemp_dir_scoped runtime-warning-budget-lib-test)"
trap 'rm -rf "$tmpdir"' EXIT

assert_success() {
  local code="$1"
  local label="$2"
  if [ "$code" -ne 0 ]; then
    log_fail "$scope" "${label}: expected success, got exit ${code}"
    exit 1
  fi
}

assert_failure() {
  local code="$1"
  local label="$2"
  if [ "$code" -eq 0 ]; then
    log_fail "$scope" "${label}: expected failure, got exit 0"
    exit 1
  fi
}

assert_equals() {
  local got="$1"
  local expected="$2"
  local label="$3"
  if [ "$got" != "$expected" ]; then
    log_fail "$scope" "${label}: expected '${expected}', got '${got}'"
    exit 1
  fi
}

run_scan() {
  local budget_file="$1"
  local log_file="$2"
  local strict="$3"
  local output_file="$4"
  local overruns=0
  local expired=0
  set +e
  runtime_warning_budget_scan "runtime-smoke" "$budget_file" "$log_file" "$strict" overruns expired >"$output_file" 2>&1
  local code=$?
  set -e
  printf '%s;%s;%s\n' "$code" "$overruns" "$expired"
}

cat >"$tmpdir/log-clean.txt" <<'EOF'
all good
EOF

cat >"$tmpdir/log-overrun.txt" <<'EOF'
portal warning
portal warning
EOF

cat >"$tmpdir/log-failpattern.txt" <<'EOF'
fatal marker
EOF

cat >"$tmpdir/budget-base.json" <<'EOF'
{
  "version": 1,
  "failPatterns": [
    { "id": "F001", "pattern": "fatal marker", "owner": "qa" }
  ],
  "warningThresholds": [
    {
      "id": "W001",
      "pattern": "portal warning",
      "defaultMax": 1,
      "envOverride": "TEST_PORTAL_WARN_MAX",
      "owner": "qa",
      "expiresOn": "2099-12-31"
    }
  ]
}
EOF

cat >"$tmpdir/budget-expired.json" <<'EOF'
{
  "version": 1,
  "failPatterns": [],
  "warningThresholds": [
    {
      "id": "W010",
      "pattern": "portal warning",
      "defaultMax": 10,
      "owner": "qa",
      "expiresOn": "2000-01-01"
    }
  ]
}
EOF

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-base.json" "$tmpdir/log-clean.txt" 0 "$tmpdir/out-1.log")
assert_success "$code" "clean log"
assert_equals "$overruns" "0" "clean log overruns"
assert_equals "$expired" "0" "clean log expired"

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-base.json" "$tmpdir/log-overrun.txt" 0 "$tmpdir/out-2.log")
assert_success "$code" "non-strict overrun"
assert_equals "$overruns" "1" "non-strict overrun count"
assert_equals "$expired" "0" "non-strict overrun expired"

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-base.json" "$tmpdir/log-overrun.txt" 1 "$tmpdir/out-3.log")
assert_failure "$code" "strict overrun"

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-base.json" "$tmpdir/log-failpattern.txt" 0 "$tmpdir/out-4.log")
assert_failure "$code" "fail pattern present"

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-expired.json" "$tmpdir/log-clean.txt" 0 "$tmpdir/out-5.log")
assert_success "$code" "expired budget non-strict"
assert_equals "$expired" "1" "expired budget count"

IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-expired.json" "$tmpdir/log-clean.txt" 1 "$tmpdir/out-6.log")
assert_failure "$code" "expired budget strict"

TEST_PORTAL_WARN_MAX=2
export TEST_PORTAL_WARN_MAX
IFS=';' read -r code overruns expired < <(run_scan "$tmpdir/budget-base.json" "$tmpdir/log-overrun.txt" 0 "$tmpdir/out-7.log")
assert_success "$code" "env override threshold"
assert_equals "$overruns" "0" "env override suppresses overrun"

log_ok "$scope" "runtime warning budget lib tests passed"
