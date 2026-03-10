#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

results_dir="experiments/perf-tuning/results/baseline-$(date +%Y%m%d-%H%M%S)"
"$repo_root/experiments/perf-tuning/run-benchmarks.sh" "$results_dir"

echo
echo "Baseline written to: $results_dir"
