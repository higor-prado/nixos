#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

scope="perf-bench"
results_dir="${1:-experiments/perf-tuning/results/$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$results_dir"/{meta,boot,runtime-health,runtime-signals}

host="$(hostname)"
timestamp="$(date --iso-8601=seconds)"

cat >"$results_dir/meta/context.txt" <<EOF
branch=$(git rev-parse --abbrev-ref HEAD)
commit=$(git rev-parse HEAD)
host=${host}
timestamp=${timestamp}
cwd=${repo_root}
EOF

{
  printf '# Performance Benchmark Summary\n\n'
  printf -- "- Branch: \`%s\`\n" "$(git rev-parse --abbrev-ref HEAD)"
  printf -- "- Commit: \`%s\`\n" "$(git rev-parse --short HEAD)"
  printf -- "- Host: \`%s\`\n" "$host"
  printf -- "- Timestamp: \`%s\`\n\n" "$timestamp"
} >"$results_dir/summary.md"

echo "[${scope}] collecting system facts"
{
  echo "hostname=$host"
  uname -a
  echo
  nproc
  echo
  free -h
  echo
  swapon --show || true
} >"$results_dir/meta/system.txt"

echo "[${scope}] benchmarking eval/build throughput"
nix shell nixpkgs#hyperfine nixpkgs#jq -c bash -lc "
  set -euo pipefail
  hyperfine --warmup 1 --runs 3 --export-json '$results_dir/build-eval.json' \
    'nix eval path:$repo_root#nixosConfigurations.predator.config.system.build.toplevel.drvPath >/dev/null' \
    'nix build --no-link path:$repo_root#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path >/dev/null' \
    'nix build --no-link path:$repo_root#nixosConfigurations.predator.config.system.build.toplevel >/dev/null'
"

printf '## Eval / Build Throughput\n\n' >>"$results_dir/summary.md"
python3 - <<'PY' "$results_dir/build-eval.json" >>"$results_dir/summary.md"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
for item in data.get("results", []):
    name = item["command"]
    mean = item["mean"]
    stddev = item.get("stddev")
    print(f"- `{name}`: mean `{mean:.3f}s`, stddev `{stddev:.3f}s`")
print()
PY

echo "[${scope}] collecting boot/session readiness"
systemd-analyze time >"$results_dir/boot/time.txt" 2>&1 || true
systemd-analyze blame >"$results_dir/boot/blame.txt" 2>&1 || true
systemd-analyze critical-chain greetd.service >"$results_dir/boot/critical-chain-greetd.txt" 2>&1 || true
systemd-analyze critical-chain graphical.target >"$results_dir/boot/critical-chain-graphical.txt" 2>&1 || true

printf '## Boot / Session Readiness\n\n' >>"$results_dir/summary.md"
printf '```text\n' >>"$results_dir/summary.md"
sed -n '1,5p' "$results_dir/boot/time.txt" >>"$results_dir/summary.md" || true
printf '```\n\n' >>"$results_dir/summary.md"

echo "[${scope}] collecting runtime desktop health gate"
if scripts/check-runtime-smoke.sh --allow-non-graphical >"$results_dir/runtime-health/smoke.txt" 2>&1; then
  echo "pass" >"$results_dir/runtime-health/status.txt"
else
  echo "fail" >"$results_dir/runtime-health/status.txt"
fi

printf '## Runtime Desktop Health\n\n' >>"$results_dir/summary.md"
printf -- "- Status: \`%s\`\n\n" "$(cat "$results_dir/runtime-health/status.txt")" >>"$results_dir/summary.md"

echo "[${scope}] collecting targeted runtime signals"
{
  echo "### sysctl"
  sysctl vm.swappiness vm.vfs_cache_pressure vm.dirty_ratio vm.dirty_background_ratio vm.compaction_proactiveness kernel.sched_autogroup_enabled 2>/dev/null || true
  echo
  echo "### cpu governor"
  cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
  echo
  echo "### zram"
  zramctl 2>/dev/null || true
} >"$results_dir/runtime-signals/system.txt"

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi --query-gpu=name,pstate,temperature.gpu,utilization.gpu,memory.used,power.draw --format=csv,noheader,nounits \
    >"$results_dir/runtime-signals/nvidia-smi.txt" 2>&1 || true
fi

nix shell nixpkgs#stress-ng -c bash -lc "
  set -euo pipefail
  stress-ng --cpu 0 --timeout 20s --metrics-brief
" >"$results_dir/runtime-signals/stress-ng.txt" 2>&1 || true

printf '## Targeted Runtime Signals\n\n' >>"$results_dir/summary.md"
printf '```text\n' >>"$results_dir/summary.md"
sed -n '1,20p' "$results_dir/runtime-signals/system.txt" >>"$results_dir/summary.md" || true
printf '```\n\n' >>"$results_dir/summary.md"
if [ -f "$results_dir/runtime-signals/nvidia-smi.txt" ]; then
  printf '```text\n' >>"$results_dir/summary.md"
  sed -n '1,5p' "$results_dir/runtime-signals/nvidia-smi.txt" >>"$results_dir/summary.md" || true
  printf '```\n\n' >>"$results_dir/summary.md"
fi

echo "[${scope}] benchmark results written to $results_dir"
