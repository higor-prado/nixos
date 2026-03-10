#!/usr/bin/env bash

audit_decision_registry_file() {
  printf '%s\n' "$REPO_ROOT/tests/pyramid/system-up-to-date-audit-decisions.tsv"
}

audit_inventory() {
  cat <<'EOF'
scripts/check-declarative-paths.sh	rg
scripts/check-flake-tracked.sh	git rg cut
scripts/check-nix-deprecations.sh	rg
scripts/check-repo-public-safety.sh	rg grep mkdir mktemp wc cp id
EOF
}

audit_inventory_scripts() {
  audit_inventory | cut -f1
}

audit_deps_for_script() {
  audit_inventory | awk -F '\t' -v script_rel="$1" '$1 == script_rel { print $2 }'
}

audit_report_sections() {
  cat <<'EOF'
policy	Policy mismatches
outdated	Outdated assumptions
private	Private-boundary violations
runtime	Runtime parity drift
skipped	Skipped checks
EOF
}

audit_section_filter() {
  # shellcheck disable=SC2016
  case "$1" in
    policy) printf '%s\n' 'NR>1 && $1 ~ /^P/' ;;
    outdated) printf '%s\n' 'NR>1 && ($1=="P004" || $1=="P006")' ;;
    private) printf '%s\n' 'NR>1 && ($1=="P001" || $1=="P002" || $1=="P003")' ;;
    runtime) printf '%s\n' 'NR>1 && $1 ~ /^R-.*-(FAIL|WARN)$/' ;;
    skipped) printf '%s\n' 'NR>1 && $1 ~ /^R-.*-SKIP$/' ;;
  esac
}

audit_write_decision_baseline() {
  local out_file="$1" exclude_emacs="$2" registry_file condition
  registry_file="$(audit_decision_registry_file)"
  {
    printf 'decision_id\tsource_doc\trule\texpected_pattern\tseverity_if_broken\n'
    while IFS=$'\t' read -r decision_id source_doc rule expected_pattern severity_if_broken condition; do
      [[ "$decision_id" == "decision_id" ]] && continue
      [[ -n "$decision_id" ]] || continue
      if [[ "$condition" == "exclude_emacs" && "$exclude_emacs" -ne 1 ]]; then
        continue
      fi
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "$decision_id" "$source_doc" "$rule" "$expected_pattern" "$severity_if_broken"
    done <"$registry_file"
  } >"$out_file"
}

audit_write_summary_markdown() {
  local summary="$1" repo="$2" output="$3" exclude_emacs="$4" report_skips="$5" check_count="$6" check_pass="$7" check_warn="$8" check_fail="$9" check_skipped="${10}" findings="${11}" high="${12}" medium="${13}" low="${14}" findings_tsv="${15}"
  local verdict="PASS"
  if [ "$check_fail" -gt 0 ] || [ "$high" -gt 0 ]; then verdict="FAIL"; elif [ "$findings" -gt 0 ] || [ "$check_warn" -gt 0 ] || { [ "$report_skips" = "1" ] && [ "$check_skipped" -gt 0 ]; }; then verdict="PASS_WITH_WARNINGS"; fi
  {
    printf '# System Up-To-Date Audit Summary\n\n## Context\n'
    printf "1. Repo: \`%s\`\n2. Output: \`%s\`\n3. Emacs excluded: \`%s\`\n4. Report context skips: \`%s\`\n" "$repo" "$output" "$( [ "$exclude_emacs" -eq 1 ] && echo yes || echo no )" "$( [ "$report_skips" = "1" ] && echo yes || echo no )"
    # shellcheck disable=SC2016
    printf '\n## Check Totals\n1. Total checks: `%s`\n2. Pass: `%s`\n3. Warn: `%s`\n4. Fail: `%s`\n5. Skipped: `%s`\n' "$check_count" "$check_pass" "$check_warn" "$check_fail" "$check_skipped"
    # shellcheck disable=SC2016
    printf '\n## Findings Totals\n1. Total inconsistencies: `%s`\n2. High: `%s`\n3. Medium: `%s`\n4. Low: `%s`\n' "$findings" "$high" "$medium" "$low"
    printf '\n## Verdict\n%s\n\n## Top Blockers\n' "$verdict"
    if [ "$findings" -eq 0 ]; then
      printf '1. None\n'
    else
      awk -F '\t' 'NR>1 && $2=="high" {print $1"\t"$2"\t"$3"\t"$4"\t"$5}' "$findings_tsv" | head -n 5 | nl -w1 -s'. ' | sed 's/\t/ | /g'
      if ! awk -F '\t' 'NR>1 && $2=="high" {found=1} END {exit(found?0:1)}' "$findings_tsv"; then printf '1. No high-severity blockers found.\n'; fi
    fi
  } >"$summary"
}

audit_append_section() {
  local out="$1" findings_tsv="$2" title="$3" selector="$4" filter
  filter="$(audit_section_filter "$selector")"
  printf '## %s\n' "$title" >>"$out"
  if awk -F '\t' "$filter {found=1} END {exit(found?0:1)}" "$findings_tsv"; then
    awk -F '\t' "$filter {print}" "$findings_tsv" | while IFS=$'\t' read -r id sev loc ev why act; do
      { printf "1. \`%s\` | \`%s\` | \`%s\`\n" "$id" "$sev" "$loc"; printf "   - evidence: \`%s\`\n" "$ev"; printf '   - why_inconsistent: %s\n' "$why"; printf '   - recommended_action: %s\n' "$act"; } >>"$out"
    done
  else
    printf '1. None\n' >>"$out"
  fi
  printf '\n' >>"$out"
}

audit_write_inconsistencies_markdown() {
  local out="$1" findings_tsv="$2"
  {
    printf '# Inconsistencies Report\n\n'
    printf 'Each finding includes: id, severity, location, evidence, why inconsistent, recommended action.\n\n'
  } >"$out"
  while IFS=$'\t' read -r selector title; do
    [[ -n "$selector" ]] || continue
    audit_append_section "$out" "$findings_tsv" "$title" "$selector"
  done < <(audit_report_sections)
}
