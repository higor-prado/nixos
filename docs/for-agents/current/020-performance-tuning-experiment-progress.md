# Performance Tuning Experiment Progress

## Status

In progress

## Related Plan

- [018-performance-tuning-experiment-plan.md](/home/higorprado/nixos/docs/for-agents/plans/018-performance-tuning-experiment-plan.md)

## Baseline

- branch: `perf-tuning-experiments`
- no benchmark harness added yet
- tracked tuning surface identified in:
  - `hardware/predator/performance.nix`
  - `hardware/predator/hardware/gpu-nvidia.nix`
  - `modules/features/core/system-base.nix`
  - `modules/features/desktop/niri.nix`
  - `modules/desktops/dms-on-niri.nix`
- shared runtime validation helper available:
  - `scripts/check-runtime-smoke.sh`

## Slices

### Planning

- created the active execution plan for benchmark-driven performance tuning
- constrained the work to branch-local experiment tooling instead of shared
  repo `scripts/`
- identified the four benchmark buckets:
  - eval/build throughput
  - boot/session readiness
  - runtime desktop health
  - targeted runtime signals
- defined the experiment weighting:
  - targeted runtime signals: `50%`
  - boot/session readiness: `35%`
  - eval/build throughput: `15%`
  - runtime desktop health: gate only, not scored

### Slice 1

- added branch-local harness under `experiments/perf-tuning/`
- added:
  - `README.md`
  - `run-baseline.sh`
  - `run-benchmarks.sh`
  - `.gitignore` for local benchmark output
- kept the experiment output in `experiments/perf-tuning/results/`, outside the
  shared repo `scripts/` surface
- validation run:
  - `bash -n experiments/perf-tuning/run-benchmarks.sh experiments/perf-tuning/run-baseline.sh`
  - `./scripts/check-docs-drift.sh`
  - `bash scripts/check-changed-files-quality.sh`
- diff result:
  - no system or HM closure change; experiment tooling only
- commit:
  - pending

## Final State

- experiment not started yet
- next step is Phase 0: benchmark harness and baseline capture
