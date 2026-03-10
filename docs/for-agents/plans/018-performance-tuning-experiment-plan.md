# Performance Tuning Experiment Plan

## Goal

Run a controlled performance-tuning experiment on this branch, centered on the
desktop workstation path (`predator`). The work must be benchmark-driven:
capture baseline numbers first, change one tuning cluster at a time, benchmark
again, and keep only changes that produce a measurable improvement or a clear
operational benefit without regressions.

## Scope

In scope:
- benchmark harness and result collection for `predator`
- tuning candidates already present in tracked config, especially:
  - `hardware/predator/performance.nix`
  - `hardware/predator/hardware/gpu-nvidia.nix`
  - `modules/features/core/system-base.nix`
  - `modules/features/desktop/niri.nix`
  - `modules/desktops/dms-on-niri.nix`
- reproducible before/after comparison of:
  - build/eval time
  - boot/session readiness
  - runtime smoke / warning budget state
  - targeted desktop/runtime signals

Out of scope:
- broad server tuning for `aurelius`
- permanent benchmark tooling in repo `scripts/`
- random shotgun sysctl edits without a benchmark hypothesis
- changing `nixpkgs` revision while tuning
- feature refactors unrelated to performance

## Current State

- Active branch for this work: `perf-tuning-experiments`
- `predator` already carries an explicit tuning layer in
  `hardware/predator/performance.nix`
- existing tracked tuning includes:
  - `systemd.oomd`
  - explicit `boot.kernel.sysctl`
  - `services.ananicy`
  - `services.smartd`
  - `intel_pstate=active`
  - `powerManagement.cpuFreqGovernor = "powersave"`
- GPU/NVIDIA-specific behavior lives in
  `hardware/predator/hardware/gpu-nvidia.nix`
- `system-base` already enables `zramSwap`
- tracked runtime validation already includes a local desktop smoke runner:
  `scripts/check-runtime-smoke.sh`
- repo `scripts/` is reserved for shared validation/safety tooling, so
  experiment-only benchmark helpers should live outside that surface

## Desired End State

- The branch contains a documented experiment workflow and baseline numbers.
- Each tuning slice has:
  - a hypothesis
  - before/after benchmark data
  - validation results
  - closure diff review
- Only tunings with defensible measured value remain.
- Experiment artifacts live in a clearly non-core location.
- Results are summarized well enough that a future keep/revert decision is easy.

## Benchmark Model

The experiment should measure four buckets.

### A. Eval / Build Throughput

Goal:
- detect whether a tuning change indirectly affects day-to-day rebuild workflow

Measurements:
- `hyperfine` over:
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Notes:
- use warm-cache runs for comparability
- record sample count and machine conditions

### B. Boot / Session Readiness

Goal:
- detect whether boot/login path improves or regresses

Measurements:
- `systemd-analyze time`
- `systemd-analyze blame`
- `systemd-analyze critical-chain greetd.service`
- if relevant, `systemd-analyze critical-chain graphical.target`

Notes:
- collect after an actual reboot for slices that affect boot, GPU, or session

### C. Runtime Desktop Health

Goal:
- ensure tuning does not degrade the actual desktop session

Measurements:
- `./scripts/check-runtime-smoke.sh --strict-backends`
- same command with `--strict-logs` when the warning budget is expected to stay stable
- count/compare warning budget overruns
- `systemctl --failed --no-pager`
- `systemctl --user --failed --no-pager`

### D. Targeted Runtime Signals

Goal:
- test the specific subsystem being tuned

Possible measurements:
- CPU / scheduler / memory tuning:
  - `stress-ng` or equivalent controlled load
  - foreground responsiveness notes
  - `vmstat`, `iostat`, `free -h`, `swapon --show`
- GPU / compositor tuning:
  - `nvidia-smi` queries
  - compositor/session startup readiness
  - VRAM/power draw snapshot before/after
- network tuning:
  - only if a change touches network stack; otherwise skip

## Experiment Layout

Use a branch-local experiment area rather than shared `scripts/`.

Recommended location:
- `experiments/perf-tuning/`

Recommended contents:
- `README.md` — how to run the experiment
- `run-baseline.sh` — capture baseline numbers
- `run-benchmarks.sh` — rerun the standard benchmark suite
- `results/` — ignored or branch-local benchmark output snapshots
- optional focused helpers per tuning cluster

This keeps experimentation out of the shared validation surface.

## Phases

### Phase 0: Baseline and Harness

Targets:
- create `experiments/perf-tuning/`
- define the exact benchmark suite
- record the starting branch and current tracked tuning values

Changes:
- add experiment-local benchmark runners
- add a results format that is easy to diff
- add a short benchmark README

Validation:
- `./scripts/run-validation-gates.sh structure`
- `bash scripts/check-changed-files-quality.sh`
- benchmark harness runs successfully without config changes

Diff expectation:
- no system or HM closure diff

Commit target:
- `chore(perf): add benchmark harness`

### Phase 1: Baseline Capture

Targets:
- capture baseline numbers before any tuning change

Changes:
- no config changes
- run and store:
  - eval/build timings
  - runtime smoke result
  - boot/session metrics if available
  - targeted runtime snapshots

Validation:
- `./scripts/run-validation-gates.sh predator`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- none; measurement only

Commit target:
- no commit required unless harness output format/docs change

### Phase 2: Memory / Scheduler Slice

Targets:
- `hardware/predator/performance.nix`
- possibly `modules/features/core/system-base.nix`

Candidate knobs:
- `vm.swappiness`
- `vm.vfs_cache_pressure`
- `vm.dirty_ratio`
- `vm.dirty_background_ratio`
- `vm.compaction_proactiveness`
- `kernel.sched_autogroup_enabled`
- `zramSwap.memoryPercent`
- `services.ananicy`

Changes:
- make one coherent memory/scheduler hypothesis at a time
- avoid touching GPU or session settings in the same slice

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- benchmark suite rerun

Diff expectation:
- closure diff only reflects the intended tuning change
- benchmark deltas must be explainable

Commit target:
- `refactor(perf): tune memory and scheduler policy`

### Phase 3: CPU Policy Slice

Targets:
- `hardware/predator/performance.nix`

Candidate knobs:
- `intel_pstate=active`
- governor choice
- any related power-policy toggles already in tracked config

Changes:
- compare current policy against one alternative at a time
- explicitly record tradeoff:
  - throughput
  - thermals
  - interactivity
  - battery/power draw, if relevant

Validation:
- same as Phase 2
- add runtime snapshots relevant to CPU behavior

Diff expectation:
- no unrelated system diff

Commit target:
- `refactor(perf): tune cpu policy`

### Phase 4: GPU / Session Slice

Targets:
- `hardware/predator/hardware/gpu-nvidia.nix`
- `modules/features/desktop/niri.nix`
- `modules/desktops/dms-on-niri.nix`

Candidate knobs:
- `hardware.nvidia.powerManagement.finegrained`
- `hardware.nvidia.dynamicBoost.enable`
- selected environment/session variables
- portal/session startup details only if evidence points there

Changes:
- touch GPU/session policy only when the benchmark data or runtime smoke gives
  a reason
- avoid changing more than one GPU/session hypothesis per slice

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`
- benchmark suite rerun
- reboot/session-readiness measurement if the slice affects boot/login

Diff expectation:
- closure diff limited to the GPU/session layer
- runtime smoke stays green

Commit target:
- `refactor(perf): tune gpu and session policy`

### Phase 5: Keep / Revert Decision

Targets:
- all experiment slices on this branch

Changes:
- compare baseline vs final results
- revert any slice with no measurable value or with ambiguous regressions
- summarize accepted vs rejected tunings

Validation:
- final benchmark rerun
- `./scripts/run-validation-gates.sh predator`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- final closure diffs match only accepted tunings

Commit target:
- `docs(perf): summarize tuning results`

## Candidate Tuning Matrix

Good first candidates:
- review `vm.swappiness` and dirty-page settings
- review `zramSwap.memoryPercent`
- review `services.ananicy` impact under compile/load
- review current CPU governor choice vs measured responsiveness

Maybe worth testing:
- `hardware.nvidia.powerManagement.finegrained`
- `hardware.nvidia.dynamicBoost.enable`

Do not touch first:
- unrelated app configs
- random kernel params copied from internet without a benchmark target
- `aurelius` tuning, unless the predator experiment clearly produces a reusable
  pattern

## Risks

- benchmark noise from normal workstation activity
- confusing warm-cache build effects with real tuning gains
- desktop-runtime improvements that hurt thermals or battery behavior
- multiple overlapping tuning changes making attribution impossible

## Rules for Execution

- one tuning hypothesis per commit
- benchmark before and after every config slice
- use `nix store diff-closures` for every evaluated Nix change
- reboot only when the slice actually affects boot/session/GPU behavior
- reject changes with no clear benefit

## Definition of Done

- benchmark harness exists and is documented
- baseline numbers are captured
- at least one tuning slice is tested with before/after data
- accepted changes have validation + benchmark evidence
- rejected changes are reverted or recorded as not worth keeping
- the branch tells a clear story about what improved and what did not
