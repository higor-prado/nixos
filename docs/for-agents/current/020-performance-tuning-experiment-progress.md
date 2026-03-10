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
  - `a133de1` `chore(perf): add benchmark harness`

### Slice 2

- adjusted the harness after the first run:
  - reduced eval/build repetitions from `5` to `3` to keep iteration cost
    practical
  - changed the automated runtime health gate to
    `./scripts/check-runtime-smoke.sh --allow-non-graphical`
- reason:
  - the branch-local runner does not inherit a graphical shell environment, so
    the raw smoke invocation produced a false negative
  - the current desktop topology also does not activate
    `xdg-desktop-portal-gtk.service`, so strict backend expectations are not a
    good automation default
- captured corrected baseline at:
  - `experiments/perf-tuning/results/baseline-20260310-182750`
- baseline summary:
  - eval drvPath: `21.023s`
  - HM build: `12.132s`
  - system build: `21.150s`
  - boot/session: `22.880s` total, `7.930s` userspace to `graphical.target`
  - runtime health gate: `pass`
  - targeted runtime:
    - governor: `powersave`
    - `stress-ng` cpu bogo ops/s: `34909.14`
    - `stress-ng` emitted an explicit note that `performance` governor may
      improve results
- next hypothesis selected:
  - test `powerManagement.cpuFreqGovernor = "performance"` on `predator`
    without changing any other tuning knob in the same slice
- validation run:
  - `experiments/perf-tuning/run-baseline.sh`
- diff result:
  - no Nix closure diff; measurement-only slice
- commit:
  - pending

### Slice 3

- tested the first real tuning hypothesis:
  - `powerManagement.cpuFreqGovernor = "powersave"` ->
    `powerManagement.cpuFreqGovernor = "performance"`
- important environment constraint:
  - `linuwu-sense` remains the owner of Acer thermal/platform behavior
  - `platform_profile` was already `balanced-performance`
  - `thermald` and `power-profiles-daemon` stayed disabled
- before/after comparison:
  - targeted runtime (`stress-ng` cpu bogo ops/s):
    - baseline: `34909.14`
    - after: `34966.66`
    - net change: negligible
  - boot/session readiness:
    - unchanged (`22.880s` total, `7.930s` userspace)
  - runtime desktop health:
    - pass before and after
  - eval/build throughput:
    - changed, but the system build benchmark had a large outlier after the test
      switch and is not attributable enough to justify keeping the tuning
- decision:
  - reject this tuning slice
  - revert to `powersave`
- reason:
  - the weighted model prioritizes runtime behavior, and the runtime gain was
    too small to justify a permanent change
  - with `intel_pstate=active` plus `balanced-performance` platform profile, the
    governor swap did not buy enough value
- validation and artifacts:
  - pre/post system and HM closure diffs were clean
  - runtime benchmark written to
    `experiments/perf-tuning/results/after-cpu-governor-performance-20260310`
- commit:
  - `11b8495` `docs(perf): record rejected cpu governor experiment`

### Slice 4

- improved the harness after the rejected governor test
- reason:
  - the current targeted runtime bucket was too CPU-centric and did not
    discriminate well for subtle policy changes on top of `intel_pstate=active`
    plus `balanced-performance` platform profile
- added a second targeted runtime probe:
  - `stress-ng --vm 8 --vm-bytes 70% --vm-keep --timeout 20s --metrics-brief`
- next tuning slices in the memory/scheduler area can now be judged against both:
  - CPU pressure
  - memory pressure
- commit:
  - `269e838` `chore(perf): extend targeted runtime benchmarks`

### Slice 5

- captured the first valid baseline with the extended runtime signal suite at:
  - `experiments/perf-tuning/results/baseline-with-vm-valid-20260310`
- valid baseline highlights:
  - runtime health: `pass`
  - CPU pressure: `35046.57` bogo ops/s
  - VM pressure: `1256149.34` bogo ops/s
  - boot/session still dominated by `NetworkManager-wait-online` and Docker on
    the path to `graphical.target`, but that path likely intersects local
    networking expectations outside the tracked surface
- next safe hypothesis selected:
  - test only `vm.swappiness = 1` (from `10`)
- reason:
  - it directly targets the memory-pressure benchmark
  - it does not conflict with `linuwu-sense`
  - it does not require changing thermal/power ownership
- commit:
  - pending

### Slice 6

- tested the `vm.swappiness = 1` hypothesis against the valid baseline with VM
  pressure included
- after benchmark:
  - `experiments/perf-tuning/results/after-swappiness-1-20260310`
- result summary:
  - runtime health: still `pass`
  - boot/session: unchanged
  - CPU pressure:
    - baseline: `35046.57` bogo ops/s
    - after: `35187.85` bogo ops/s
    - tiny improvement, not meaningful
  - VM pressure:
    - baseline: `1256149.34` bogo ops/s
    - after: `1255359.97` bogo ops/s
    - slight regression (`-0.063%`)
  - eval/build throughput:
    - no meaningful improvement
- decision:
  - reject the tuning and revert to `vm.swappiness = 10`
- reason:
  - the weighted model prioritizes targeted runtime signals
  - the memory-focused probe did not improve
  - no compensating gain elsewhere justified keeping the change
- commit:
  - pending

## Final State

- experiment not started yet
- next step is Phase 0: benchmark harness and baseline capture
