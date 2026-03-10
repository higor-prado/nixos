# Option Migration Removal And Validation Simplification Progress

Status: completed

Plan:

- `docs/for-agents/plans/008-option-migration-removal-and-validation-simplification-plan.md`

Historical note:

This progress file records a completed cleanup. The present tense below refers to
the state observed while that cleanup was being executed.

## Baseline

Captured on current `HEAD` before any simplification edits.

Validation:

1. `./scripts/run-validation-gates.sh structure` -> pass
2. `./scripts/run-validation-gates.sh predator` -> pass
3. `./scripts/run-validation-gates.sh aurelius` -> pass
4. `./scripts/check-docs-drift.sh` -> pass
5. `./scripts/check-repo-public-safety.sh` -> pass

Baselines:

1. predator system closure:
   `/nix/store/hhm3pd23c7n4wgxg1iw1688jgjlnis29-nixos-system-predator-26.05.20260308.9dcb002`
2. predator home-manager closure:
   `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`

Inventory snapshot:

1. top-level shell scripts: `23`
2. test shell scripts: `6`
3. repo files referencing option-migration surface: `25`

## Findings Snapshot

Confirmed during planning:

1. `_migration-registry.nix` is still in the live host eval path through
   `option-migrations`, but no tracked config now uses the removed options.
2. `check-option-migrations.sh` only remains useful if the migration compatibility
   layer remains alive.
3. `check-test-pyramid-contracts.sh` mostly validates synthetic metadata and
   fixtures that do not protect current tracked host behavior.
4. `tests/scripts/ownership-boundary-fixture-test.sh` is stale and references
   `_old-modules/core`, which no longer exists.
5. `run-full-validation.sh` is currently only a thin wrapper around
   `run-validation-gates.sh all`.

## Phase Checklist

- [x] Phase 0: baseline capture
- [x] Phase 1: remove option-migration compatibility stack
- [x] Phase 2: remove obsolete option-migration gate and fixture
- [x] Phase 3: remove stale ownership-boundary fixture
- [x] Phase 4: simplify synthetic test-pyramid layer
- [x] Phase 5: remove redundant full-validation wrapper
- [x] Phase 6: re-evaluate remaining validation meta-layer

## Completed Slice: Phase 5

What changed:

1. removed the redundant `run-full-validation.sh` wrapper
2. simplified `check-validation-source-of-truth.sh` so it no longer enforces a
   wrapper that adds no logic
3. removed the wrapper from the shared script registry and validation docs

Validation:

1. `./scripts/run-validation-gates.sh structure` -> pass
2. `./scripts/check-docs-drift.sh` -> pass
3. `./scripts/check-validation-source-of-truth.sh` -> pass
4. `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
5. `bash tests/scripts/gate-cli-contracts-test.sh` -> pass
6. `bash scripts/check-changed-files-quality.sh` -> pass

Note:

1. direct runs of `check-extension-contracts.sh` / `gate-cli-contracts-test.sh`
   required real Nix daemon access outside the sandbox; the repo logic itself was
   fine

## Phase 6 Decision

Decision: keep `tests/pyramid/shared-script-registry.tsv` and
`scripts/check-validation-source-of-truth.sh` for now.

Why:

1. after the simplification, they still protect a real current workflow:
   top-level shared script inventory plus CI/stage routing through
   `run-validation-gates.sh`
2. the low-value synthetic pyramid metadata is gone, so this remaining meta-layer is
   smaller and now tied to live workflow surfaces
3. removing it immediately would save little while also dropping one of the few
   automated checks preventing validation-topology drift

Checkpoint metrics after the plan:

1. top-level shell scripts: `20`
2. test shell scripts: `5`
3. shared script registry rows: `20`

## Completed Slice: Phases 1-4

These phases were executed together because the old migration gate and synthetic
test-pyramid layer were coupled to the live `option-migrations` aspect. Removing
the compatibility stack without removing those validation layers would have left
the structure gate intentionally broken.

What changed:

1. deleted the live option-migration compatibility stack
2. removed `option-migrations` from tracked hosts, templates, and generator fixtures
3. removed `scripts/check-option-migrations.sh`
4. removed `scripts/check-test-pyramid-contracts.sh`
5. removed the synthetic pyramid config + host/profile/pack/option fixtures
6. removed the stale `ownership-boundary-fixture-test.sh`
7. rewrote docs to describe the post-migration state instead of an active
   compatibility workflow

Validation:

1. `./scripts/run-validation-gates.sh structure` -> pass
2. `./scripts/run-validation-gates.sh predator` -> pass
3. `./scripts/run-validation-gates.sh aurelius` -> pass
4. `./scripts/check-docs-drift.sh` -> pass
5. `./scripts/check-repo-public-safety.sh` -> pass
6. `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
7. `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass

Post-slice closures:

1. predator system closure:
   `/nix/store/2v6l018x6jpqs7g2v9nvkl8rnjv0s262-nixos-system-predator-26.05.20260308.9dcb002`
2. predator home-manager closure:
   `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`

Diff results:

1. `nix store diff-closures /tmp/migration-removal-before-system /tmp/migration-removal-after-phase1-system`
   -> no semantic output
2. `nix store diff-closures /tmp/migration-removal-before-hm /tmp/migration-removal-after-phase1-hm`
   -> no output

## Notes

Keep the user’s unrelated local `flake.lock` modification untouched throughout this
plan.
