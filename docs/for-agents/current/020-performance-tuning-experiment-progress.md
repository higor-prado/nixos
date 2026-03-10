# Performance Tuning Experiment Progress

## Status

Planned

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

## Final State

- experiment not started yet
- next step is Phase 0: benchmark harness and baseline capture
