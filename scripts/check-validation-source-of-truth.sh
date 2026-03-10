#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/validation_host_topology.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/validation_host_topology.sh"
enter_repo_root "${BASH_SOURCE[0]}"

workflow_file=".github/workflows/validate.yml"
gate_runner="./scripts/run-validation-gates.sh"
gate_runner_file="scripts/run-validation-gates.sh"
audit_entrypoint_file="scripts/audit-system-up-to-date.sh"
audit_inventory_file="scripts/lib/system_up_to_date_audit.sh"
registry_file="tests/pyramid/shared-script-registry.tsv"
validation_doc="docs/for-agents/005-validation-gates.md"

fail=0

report_fail() {
  log_fail "validation-source" "$1"
  fail=1
}

require_cmds "validation-source" "awk" "find" "rg"

if [[ ! -f "$registry_file" ]]; then
  report_fail "missing shared script registry: $registry_file"
  exit 1
fi

require_workflow_line() {
  local snippet="$1"
  if ! rg -q --fixed-strings "$snippet" "$workflow_file"; then
    report_fail "workflow missing expected gate runner command: $snippet"
  fi
}

while IFS= read -r script_path; do
  [[ -n "$script_path" ]] || continue
  if ! awk -F '\t' -v script_path="$script_path" 'NR > 1 && $1 == script_path { found = 1 } END { exit(found ? 0 : 1) }' "$registry_file"; then
    report_fail "top-level shared script is missing from registry: $script_path"
  fi
done < <(find scripts -maxdepth 1 -type f -name '*.sh' | sort)

while IFS=$'\t' read -r script_path category _; do
  [[ "$script_path" == "script" ]] && continue
  [[ -n "$script_path" ]] || continue

  if [[ ! -f "$script_path" ]]; then
    report_fail "registry references missing script: $script_path"
    continue
  fi

  script_name="$(basename "$script_path")"

  case "$category" in
    gate-runner)
      if [[ "$script_path" != "$gate_runner_file" ]]; then
        report_fail "gate-runner registry entry must be ${gate_runner_file}: $script_path"
      fi
      ;;
    gate-check)
      if ! rg -q --fixed-strings "\"${script_name}\"" "$gate_runner_file"; then
        report_fail "gate-check is not referenced by ${gate_runner_file}: $script_name"
      fi
      ;;
    audit-leaf)
      if ! rg -q --fixed-strings "$script_name" "$audit_entrypoint_file" "$audit_inventory_file"; then
        report_fail "audit-leaf is not referenced by audit inventory: $script_name"
      fi
      ;;
    shared-aux)
      if ! rg -q --fixed-strings "$script_name" "$validation_doc"; then
        report_fail "shared-aux is not documented in ${validation_doc}: $script_name"
      fi
      ;;
    *)
      report_fail "registry entry has unknown category '${category}': $script_path"
      ;;
  esac
done <"$registry_file"

require_workflow_line "${gate_runner} structure"
while IFS= read -r stage_name; do
  [[ -n "$stage_name" ]] || continue
  require_workflow_line "${gate_runner} ${stage_name}"
done < <(ci_validation_host_stages)

ci_host_pattern="$(while IFS= read -r stage_name; do
  [[ -n "$stage_name" ]] || continue
  validation_stage_host "$stage_name"
done < <(ci_validation_host_stages) | paste -sd'|' -)"

if rg -n \
  "check-desktop-capability-usage\\.sh|check-option-declaration-boundary\\.sh|check-desktop-composition-matrix\\.sh|nix flake metadata|nix eval path:\\\$PWD#nixosConfigurations\\.(${ci_host_pattern})|nix build --no-link path:\\\$PWD#nixosConfigurations\\.(${ci_host_pattern})" \
  "$workflow_file" >/dev/null; then
  report_fail "workflow contains direct gate commands; use ${gate_runner} stages instead"
fi

if [ "$fail" -ne 0 ]; then
  exit 1
fi

echo "[validation-source] ok: CI/local validation are routed through ${gate_runner}"
