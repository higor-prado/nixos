#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=lib/common.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"
# shellcheck source=lib/validation_host_topology.sh
# shellcheck disable=SC1091
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib/validation_host_topology.sh"
enter_repo_root "${BASH_SOURCE[0]}"

scope="maintainability-kpis"
default_output_dir="reports/nixos/artifacts/932-maintainability/00-baseline"
output_dir="$default_output_dir"
skip_gates=0

usage() {
  cat <<'EOF'
Usage: scripts/report-maintainability-kpis.sh [--skip-gates] [output_dir]

Options:
  --skip-gates  Do not run validation gate timings; write skipped markers instead.
  -h, --help    Show this help text.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-gates)
      skip_gates=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ "$output_dir" != "$default_output_dir" ]; then
        log_fail "$scope" "only one output_dir argument is allowed"
        usage >&2
        exit 1
      fi
      output_dir="$1"
      shift
      ;;
  esac
done

require_cmds "$scope" find wc sort awk head sed grep git tee

mkdir -p "$output_dir"

meta_file="$output_dir/00-baseline-meta.txt"
script_metrics_file="$output_dir/01-script-metrics.txt"
top10_file="$output_dir/02-top10-scripts.txt"
structure_gate_file="$output_dir/03-gate-structure.txt"
docs_distribution_file="$output_dir/06-doc-distribution.txt"
summary_file="$output_dir/07-summary.md"

declare -A host_stage_files=()
gate_file_index=4
while IFS= read -r stage_name; do
  [[ -n "$stage_name" ]] || continue
  host_stage_files["$stage_name"]="$output_dir/$(printf '%02d' "$gate_file_index")-gate-${stage_name}.txt"
  gate_file_index=$((gate_file_index + 1))
done < <(validation_host_stages)

mapfile -t script_files < <(find scripts -type f -name '*.sh' | LC_ALL=C sort)
if [ "${#script_files[@]}" -eq 0 ]; then
  log_fail "$scope" "no shell scripts found under scripts/"
  exit 1
fi

scripts_count="${#script_files[@]}"
scripts_total_loc="$(wc -l "${script_files[@]}" | awk 'END { print $1 }')"
scripts_avg_loc="$(awk -v total="$scripts_total_loc" -v count="$scripts_count" 'BEGIN { printf "%.2f\n", total / count }')"

{
  echo "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "branch=$(git rev-parse --abbrev-ref HEAD)"
  echo "commit=$(git rev-parse HEAD)"
  echo "output_dir=$output_dir"
  echo "skip_gates=$skip_gates"
} >"$meta_file"

{
  echo "scripts_count=$scripts_count"
  echo "scripts_total_loc=$scripts_total_loc"
  echo "scripts_avg_loc=$scripts_avg_loc"
} >"$script_metrics_file"

find scripts -type f -name '*.sh' -print0 \
  | xargs -0 wc -l \
  | sed '$d' \
  | sort -nr \
  | head -n 10 >"$top10_file"

run_timed_stage() {
  local stage="$1"
  local output_file="$2"
  {
    echo "stage=$stage"
    echo "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    TIMEFORMAT='real=%3R user=%3U sys=%3S'
    time ./scripts/run-validation-gates.sh "$stage"
  } 2>&1 | tee "$output_file"
}

count_markdown_files() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    echo 0
    return 0
  fi

  find "$dir" -maxdepth 1 -type f -name '*.md' | wc -l | awk '{print $1}'
}

if [ "$skip_gates" -eq 1 ]; then
  printf 'stage=structure\nskipped=1\nreason=--skip-gates\n' >"$structure_gate_file"
  while IFS= read -r stage_name; do
    [[ -n "$stage_name" ]] || continue
    printf 'stage=%s\nskipped=1\nreason=--skip-gates\n' "$stage_name" >"${host_stage_files[$stage_name]}"
  done < <(validation_host_stages)
else
  run_timed_stage "structure" "$structure_gate_file"
  while IFS= read -r stage_name; do
    [[ -n "$stage_name" ]] || continue
    run_timed_stage "$stage_name" "${host_stage_files[$stage_name]}"
  done < <(validation_host_stages)
fi

for_agents_root_count="$(count_markdown_files docs/for-agents)"
for_agents_historical_count="$(count_markdown_files docs/for-agents/archive)"
for_humans_root_count="$(count_markdown_files docs/for-humans)"

{
  echo "for_agents_root_docs=$for_agents_root_count"
  echo "for_agents_historical_docs=$for_agents_historical_count"
  echo "for_humans_root_docs=$for_humans_root_count"
} >"$docs_distribution_file"

extract_time() {
  local file="$1"
  local value
  value="$(grep -E '^real=' "$file" | tail -n 1 | awk -F'[ =]' '{print $2}' || true)"
  if [ -z "$value" ]; then
    echo "n/a"
  else
    echo "$value"
  fi
}

structure_real="$(extract_time "$structure_gate_file")"

{
  echo "# Maintainability KPI Baseline"
  echo
  echo "- Date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "- Branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "- Commit: $(git rev-parse --short HEAD)"
  echo
  echo "## Script Metrics"
  echo "- Script count: $scripts_count"
  echo "- Total script LOC: $scripts_total_loc"
  echo "- Average LOC per script: $scripts_avg_loc"
  echo
  echo "## Top 10 Largest Scripts"
  sed 's/^/- /' "$top10_file"
  echo
  echo "## Gate Timings (real seconds)"
  echo "- structure: $structure_real"
  while IFS= read -r stage_name; do
    [[ -n "$stage_name" ]] || continue
    stage_real="$(extract_time "${host_stage_files[$stage_name]}")"
    echo "- ${stage_name}: ${stage_real}"
  done < <(validation_host_stages)
  echo
  echo "## Docs Distribution"
  echo "- docs/for-agents root: $for_agents_root_count"
  echo "- docs/for-agents historical: $for_agents_historical_count"
  echo "- docs/for-humans root: $for_humans_root_count"
} >"$summary_file"

echo "[$scope] ok: baseline artifacts written to $output_dir"
