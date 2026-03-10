#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/system_up_to_date_audit.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/system_up_to_date_audit.sh"
enter_repo_root "${BASH_SOURCE[0]}"

usage() {
  cat <<'EOF'
Usage:
  scripts/audit-system-up-to-date.sh [--output <dir>] [--strict] [--exclude-emacs|--include-emacs] [--allow-dirty]

Options:
  --output <dir>     Write report artifacts to this directory.
  --strict           Exit non-zero when any inconsistency is found.
  --exclude-emacs    Exclude emacs-related findings/checks (default).
  --include-emacs    Include emacs-related findings/checks.
  --allow-dirty      Allow running in a dirty git worktree.
  -h, --help         Show this help.

Environment:
  AUDIT_REPORT_CONTEXT_SKIPS=1
    Report context/sudo skips as low-severity findings.
EOF
}

STRICT=0
EXCLUDE_EMACS=1
ALLOW_DIRTY=0
OUTPUT_DIR=""
REPORT_CONTEXT_SKIPS="${AUDIT_REPORT_CONTEXT_SKIPS:-0}"
mapfile -t SCRIPTS < <(audit_inventory_scripts)

while [ "$#" -gt 0 ]; do
  case "$1" in
    --output) OUTPUT_DIR="${2:-}"; shift 2 ;;
    --strict) STRICT=1; shift ;;
    --exclude-emacs) EXCLUDE_EMACS=1; shift ;;
    --include-emacs) EXCLUDE_EMACS=0; shift ;;
    --allow-dirty) ALLOW_DIRTY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log_fail "system-up-to-date-audit" "unknown argument: $1"; usage >&2; exit 2 ;;
  esac
done

if [ "$ALLOW_DIRTY" -ne 1 ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --porcelain=v1 || true)"
  [ -z "$dirty" ] || { log_fail "system-up-to-date-audit" "git worktree is dirty; re-run with --allow-dirty to override"; exit 2; }
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$REPO_ROOT/reports/system-up-to-date-$(date +%Y%m%d-%H%M%S)"
fi

RAW_DIR="$OUTPUT_DIR/raw"
SUMMARY_FILE="$OUTPUT_DIR/summary.md"
INCONS_FILE="$OUTPUT_DIR/inconsistencies.md"
MATRIX_FILE="$OUTPUT_DIR/scripts-matrix.csv"
FINDINGS_TSV="$RAW_DIR/findings.tsv"
CHECKS_TSV="$RAW_DIR/check-status.tsv"
mkdir -p "$RAW_DIR"

note_finding() { printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" >>"$FINDINGS_TSV"; }
count_status() { awk -F '\t' -v s="$1" 'NR>1 && $2==s {c++} END {print c+0}' "$CHECKS_TSV"; }
count_findings() { awk 'NR>1 {c++} END {print c+0}' "$FINDINGS_TSV"; }
count_severity() { awk -F '\t' -v s="$1" 'NR>1 && $2==s {c++} END {print c+0}' "$FINDINGS_TSV"; }

run_capture() {
  local name="$1" log="$2" code=0 status="pass"
  shift 2
  "$@" >"$log" 2>&1 || code=$?
  if [ "$code" -ne 0 ]; then
    status="fail"
  elif rg -qi '(^|[^a-z])(warn|warning)([^a-z]|$)|\[warn\]|\bWARN\b' "$log" >/dev/null 2>&1; then
    status="warn"
  fi
  printf '%s\t%s\t%s\t%s\n' "$name" "$status" "$code" "$log" >>"$CHECKS_TSV"
}

mark_skipped() {
  local name="$1" reason="$2" log="$3"
  printf 'SKIPPED: %s\n' "$reason" >"$log"
  printf '%s\t%s\t%s\t%s\n' "$name" "skipped" "-" "$log" >>"$CHECKS_TSV"
}

record_dependencies() {
  local script_rel="$1" base="$2" dep
  local deps_log="$RAW_DIR/${base}.deps.log"
  local missing=0
  : >"$deps_log"
  for dep in $(audit_deps_for_script "$script_rel"); do
    if command -v "$dep" >/dev/null 2>&1; then
      printf 'ok %s -> %s\n' "$dep" "$(command -v "$dep")" >>"$deps_log"
    else
      printf 'missing %s\n' "$dep" >>"$deps_log"
      missing=$((missing + 1))
    fi
  done
  if [ "$missing" -gt 0 ]; then
    run_capture "deps:$script_rel" "$RAW_DIR/${base}.deps-status.log" false
    return 1
  fi
  run_capture "deps:$script_rel" "$RAW_DIR/${base}.deps-status.log" true
}

write_matrix_row() {
  local script_rel="$1" script_status="$2" incons="$3" notes="$4"
  printf '%s,%s,%s,%s,"%s"\n' "$script_rel" "$script_status" "keep" "$incons" "$notes" >>"$MATRIX_FILE"
}

audit_write_decision_baseline "$RAW_DIR/decision-baseline.tsv" "$EXCLUDE_EMACS"
printf 'id\tseverity\tlocation\tevidence\twhy_inconsistent\trecommended_action\n' >"$FINDINGS_TSV"
printf 'check\tstatus\texit_code\tlog_path\n' >"$CHECKS_TSV"
printf 'script,status,classification,inconsistency_count,notes\n' >"$MATRIX_FILE"

(
  cd "$REPO_ROOT"
  rg --files scripts | sort >"$RAW_DIR/scripts-list.txt"
  if [ "$EXCLUDE_EMACS" -eq 1 ]; then
    rg -n 'emacs|doom|spacemacs' home modules config scripts docs >"$RAW_DIR/emacs-reference-scan.txt" 2>/dev/null || true
  fi
)

for script_rel in "${SCRIPTS[@]}"; do
  script_path="$REPO_ROOT/$script_rel"
  base="$(basename "$script_rel" .sh)"
  script_incons=0
  notes=()

  if [ ! -f "$script_path" ]; then
    note_finding "S-MISSING-$base" "high" "$script_rel" "$RAW_DIR/scripts-list.txt" \
      "Script listed in audit inventory is missing from repository." \
      "Restore script or update the audit inventory."
    write_matrix_row "$script_rel" "fail" 1 "missing script file"
    continue
  fi

  bashn_log="$RAW_DIR/${base}.bashn.log"
  run_capture "bash-n:$script_rel" "$bashn_log" bash -n "$script_path"
  bashn_status="$(awk -F '\t' -v n="bash-n:$script_rel" '$1==n {print $2}' "$CHECKS_TSV" | tail -n1)"
  if [ "$bashn_status" = "fail" ]; then
    script_incons=$((script_incons + 1)); notes+=("bash -n failed")
    note_finding "S-BASHN-$base" "high" "$script_rel" "$bashn_log" \
      "Script has syntax errors and cannot be relied on for audit automation." \
      "Fix shell syntax before using script in validation pipelines."
  fi

  if command -v shellcheck >/dev/null 2>&1; then
    shellcheck_log="$RAW_DIR/${base}.shellcheck.log"
    run_capture "shellcheck:$script_rel" "$shellcheck_log" shellcheck "$script_path"
    shellcheck_status="$(awk -F '\t' -v n="shellcheck:$script_rel" '$1==n {print $2}' "$CHECKS_TSV" | tail -n1)"
    if [ "$shellcheck_status" = "fail" ] || [ "$shellcheck_status" = "warn" ]; then
      script_incons=$((script_incons + 1)); notes+=("shellcheck issues")
      note_finding "S-SHC-$base" "low" "$script_rel" "$shellcheck_log" \
        "Shellcheck reported quality issues that can hide runtime edge cases." \
        "Resolve shellcheck findings or document suppressions with justification."
    fi
  else
    mark_skipped "shellcheck:$script_rel" "shellcheck not installed" "$RAW_DIR/${base}.shellcheck.log"
  fi

  if ! record_dependencies "$script_rel" "$base"; then
    script_incons=$((script_incons + 1)); notes+=("missing dependencies")
    note_finding "S-DEPS-$base" "medium" "$script_rel" "$RAW_DIR/${base}.deps.log" \
      "Script requires commands that are not currently available in PATH." \
      "Install missing dependencies or gate the script with preflight checks."
  fi

  run_capture "exec:$script_rel" "$RAW_DIR/${base}.exec.log" bash "$script_path"
  exec_status="$(awk -F '\t' -v n="exec:$script_rel" '$1==n {print $2}' "$CHECKS_TSV" | tail -n1)"
  case "$exec_status" in
    fail)
      script_incons=$((script_incons + 1)); notes+=("runtime check failed")
      note_finding "R-${base}-FAIL" "medium" "$script_rel" "$RAW_DIR/${base}.exec.log" \
        "Runtime execution failed, indicating drift or unmet assumptions." \
        "Review log evidence and decide whether to repair script or environment."
      ;;
    warn)
      script_incons=$((script_incons + 1)); notes+=("runtime check reported warnings")
      note_finding "R-${base}-WARN" "low" "$script_rel" "$RAW_DIR/${base}.exec.log" \
        "Runtime execution completed with warnings, indicating partial drift." \
        "Inspect warnings and decide whether to tighten checks or accept documented exceptions."
      ;;
    skipped)
      skip_reason="$(sed -n 's/^SKIPPED: //p' "$RAW_DIR/${base}.exec.log" | head -n1 || true)"
      notes+=("runtime check skipped: ${skip_reason:-unspecified}")
      if [ "$REPORT_CONTEXT_SKIPS" = "1" ]; then
        script_incons=$((script_incons + 1))
        note_finding "R-${base}-SKIP" "low" "$script_rel" "$RAW_DIR/${base}.exec.log" \
          "Runtime check could not run in current context." \
          "Re-run on target host/context to complete coverage."
      fi
      ;;
  esac

  [ "${#notes[@]}" -gt 0 ] || notes+=("no inconsistencies detected")
  joined_notes="$(printf '%s; ' "${notes[@]}")"; joined_notes="${joined_notes%; }"
  script_status="ok"; [ "$script_incons" -gt 0 ] && script_status="warn"; [ "$bashn_status" = "fail" ] || [ "$exec_status" = "fail" ] && script_status="fail"
  write_matrix_row "$script_rel" "$script_status" "$script_incons" "$joined_notes"
done

check_count="$(awk 'NR>1 {c++} END {print c+0}' "$CHECKS_TSV")"
check_pass="$(count_status pass)"; check_warn="$(count_status warn)"; check_fail="$(count_status fail)"; check_skipped="$(count_status skipped)"
finding_count="$(count_findings)"; severity_high="$(count_severity high)"; severity_medium="$(count_severity medium)"; severity_low="$(count_severity low)"

audit_write_summary_markdown \
  "$SUMMARY_FILE" "$REPO_ROOT" "$OUTPUT_DIR" "$EXCLUDE_EMACS" "$REPORT_CONTEXT_SKIPS" \
  "$check_count" "$check_pass" "$check_warn" "$check_fail" "$check_skipped" \
  "$finding_count" "$severity_high" "$severity_medium" "$severity_low" "$FINDINGS_TSV"

audit_write_inconsistencies_markdown "$INCONS_FILE" "$FINDINGS_TSV"

if [ "$STRICT" -eq 1 ] && [ "$finding_count" -gt 0 ]; then
  echo "Audit completed with inconsistencies (strict mode)." >&2
  exit 1
fi

echo "Audit completed: $OUTPUT_DIR"
