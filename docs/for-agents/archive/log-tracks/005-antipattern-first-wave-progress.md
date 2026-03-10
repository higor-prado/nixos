# Antipattern First-Wave Progress

Date: 2026-03-09
Plan: `docs/for-agents/plans/003-antipattern-first-wave-plan.md`
Status: in progress

## Item 1: Remove `host.descriptor` Dead Mirror

Status: complete

Baseline:
- repo-wide search showed writes in host modules, templates, fixtures, and docs
- no live module consumer was found under `modules/`, `hardware/`, `pkgs/`, or `scripts/`
- `docs/for-agents/999-lessons-learned.md` still claimed the option had active module consumers

Planned validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- repo-wide `rg -n "host\\.descriptor" modules hardware pkgs scripts docs tests templates -g '!reports/**'`

Result:
- removed `options.host.descriptor` from `modules/features/core-options.nix`
- removed `host.descriptor` writes from tracked host modules
- updated host skeleton templates and fixture outputs to stop emitting the dead mirror
- corrected agent docs to treat `hardware/host-descriptors.nix` as the single descriptor source
- added a migration-registry removal entry for `host.descriptor`

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- repo-wide search now finds `host.descriptor` only in plan/diagnostic/progress docs and the migration message

Diff review:
- `git diff --stat` showed a pure removal-heavy slice with no unexpected live-config additions

## Item 2: Move Catppuccin Wiring to Theme Ownership

Status: complete

Baseline:
- `home-manager-settings.nix` imported `config.host.inputs.catppuccin.homeModules.catppuccin`
- `theme.nix` owned the Catppuccin option tree but not the framework import
- baseline closures captured at `/tmp/predator-item2-before` and `/tmp/hm-item2-before`
- direct `nix eval` of `home-manager.users.higorprado.catppuccin` is not a valid regression probe on current HEAD because upstream removed `catppuccin.gtk.accent`, and the attr eval already fails before this refactor

Planned validation:
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-item2-after`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-item2-after`
- `nix store diff-closures /tmp/predator-item2-before /tmp/predator-item2-after`
- `nix store diff-closures /tmp/hm-item2-before /tmp/hm-item2-after`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Result:
- `home-manager-settings.nix` now keeps only HM plumbing and host-context forwarding
- Catppuccin framework import moved under theme ownership via `den.aspects.theme.nixos`
- the first attempt using `host` inside HM `imports` caused infinite recursion; the final design avoids that by wiring the import from the NixOS side

Validation:
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-item2-after` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-item2-after` -> pass
- `nix store diff-closures /tmp/predator-item2-before /tmp/predator-item2-after` -> empty
- `nix store diff-closures /tmp/hm-item2-before /tmp/hm-item2-after` -> empty
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass

## Item 3: Clarify `check-runtime-smoke.sh` Boundary

Status: complete

Decision:
- keep `check-runtime-smoke.sh` as a tracked gate-check
- make its scope explicit: it is the local predator desktop runtime smoke gate
- do not parameterize it into a fake generic multi-host runner in this wave

Planned validation:
- `shellcheck scripts/check-runtime-smoke.sh scripts/run-validation-gates.sh`
- `bash tests/scripts/gate-cli-contracts-test.sh`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `./scripts/check-validation-source-of-truth.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Result:
- `check-runtime-smoke.sh` now declares itself as the local predator desktop runtime smoke check
- the script fails early when run on the wrong host instead of pretending to be generic
- the gate runner help, shared-script registry, test pyramid metadata, and validation docs all describe the same predator-scoped boundary

Validation:
- `shellcheck scripts/check-runtime-smoke.sh scripts/run-validation-gates.sh` -> pass
- `bash tests/scripts/gate-cli-contracts-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `./scripts/check-validation-source-of-truth.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/report-maintainability-kpis.sh --skip-gates` -> pass

## Item 4: Reduce Hardcoded Validation Host Topology

Status: complete

Decision:
- declare the shared validation host topology once in `scripts/lib/validation_host_topology.sh`
- have the gate runner, KPI report, and source-of-truth checks consume that declaration
- keep `check-config-contracts.sh` host semantics explicit for now; this slice is about shared stage topology, not rewriting semantic assertions

Planned validation:
- `shellcheck scripts/run-validation-gates.sh scripts/report-maintainability-kpis.sh scripts/check-validation-source-of-truth.sh scripts/check-test-pyramid-contracts.sh scripts/lib/validation_host_topology.sh`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `bash tests/scripts/gate-cli-contracts-test.sh`
- `./scripts/check-validation-source-of-truth.sh`
- `./scripts/run-validation-gates.sh structure`
- `bash scripts/check-changed-files-quality.sh`
- `./scripts/report-maintainability-kpis.sh --skip-gates`
- `./scripts/check-docs-drift.sh`

Result:
- declared the shared validation host topology once in `scripts/lib/validation_host_topology.sh`
- `run-validation-gates.sh` now uses that declaration for the `all` host-stage sequence
- `report-maintainability-kpis.sh` now derives host-stage timing files from the declared topology instead of hardcoding only predator/server-example
- `check-validation-source-of-truth.sh` now derives required CI stage commands from the declared CI subset
- fixture coverage now includes the Aurelius stage explicitly

Validation:
- `shellcheck scripts/run-validation-gates.sh scripts/report-maintainability-kpis.sh scripts/check-validation-source-of-truth.sh scripts/check-test-pyramid-contracts.sh scripts/lib/validation_host_topology.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash tests/scripts/gate-cli-contracts-test.sh` -> pass
- `./scripts/check-validation-source-of-truth.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/report-maintainability-kpis.sh --skip-gates` -> pass
- `./scripts/check-docs-drift.sh` -> pass
