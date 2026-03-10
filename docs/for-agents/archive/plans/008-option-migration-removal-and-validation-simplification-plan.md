# Option Migration Removal And Validation Simplification Plan

Status: completed

## Goal

Remove the finished option-migration compatibility layer and simplify tests/scripts
that no longer protect real regressions in the current workflow.

The main simplification principle for this plan is:

1. Keep checks that protect real tracked host behavior, generator correctness, or
   safety boundaries.
2. Remove checks whose only purpose is validating historical migration bookkeeping
   or synthetic metadata about validation itself.

## Current Findings

### 1. The option-migration stack is real, but no longer needed by tracked config

Current live path:

1. tracked hosts import `option-migrations`
2. `modules/features/option-migrations.nix` imports
   `modules/lib/_migration-registry.nix`
3. the registry is converted into real module imports via:
   - `lib.mkAliasOptionModule`
   - `lib.mkRemovedOptionModule`

This is not just a legacy test artifact.

However, current tracked code no longer uses the removed option paths. Repo-wide
search finds them only in:

1. the migration registry
2. the migration gate
3. docs / plans / progress logs

So the stack now mainly provides compatibility for stale private config, stale old
branches, and better error messages for removed options.

If the migration era is considered closed, this whole compatibility layer can be
removed.

### 2. `check-option-migrations.sh` mostly enforces the compatibility policy itself

`scripts/check-option-migrations.sh` is only useful if the migration registry stays
alive.

Once the registry and `option-migrations` aspect are removed, the gate becomes dead
weight and should be deleted together with:

1. `tests/fixtures/option-migration-lifecycle/migration-registry.json`
2. references in `tests/pyramid/config-test-pyramid.json`
3. references in `tests/pyramid/shared-script-registry.tsv`
4. docs that describe option-migration policy as an active process

### 3. The synthetic test-pyramid layer has drifted into meta-bookkeeping

`scripts/check-test-pyramid-contracts.sh` currently validates:

1. `tests/pyramid/config-test-pyramid.json`
2. synthetic fixtures for:
   - host addition
   - profile addition
   - pack addition
   - option migration lifecycle
3. the audit decision registry header
4. the existence of `scripts/lib/validation_host_topology.sh`

Most of these fixtures are not consumed by real repo workflows. They are only
consumed by the meta-check that validates the metadata file itself.

The strongest examples are:

1. `tests/fixtures/host-addition/host-descriptor.json`
2. `tests/fixtures/profile-addition/profile-metadata.json`
3. `tests/fixtures/pack-addition/pack-registry.json`
4. `tests/fixtures/option-migration-lifecycle/migration-registry.json`

At the moment, these synthetic fixtures are not protecting tracked host behavior.
They are mainly protecting the existence and shape of the synthetic test-pyramid
description.

### 4. `run-full-validation.sh` is probably removable

`scripts/run-full-validation.sh` is currently only:

```bash
exec "$REPO_ROOT/scripts/run-validation-gates.sh" all
```

It is a thin wrapper with no additional logic. If no external workflow or user
habit depends on the name, the wrapper can be removed and the source-of-truth gate
can stop enforcing it.

### 5. `ownership-boundary-fixture-test.sh` is stale and currently useless

`tests/scripts/ownership-boundary-fixture-test.sh` scans `_old-modules/core`, which
no longer exists in the repo. So the test passes without protecting a real current
boundary.

This should be removed unless it is rewritten to validate a real current ownership
rule.

### 6. `shared-script-registry.tsv` and `check-validation-source-of-truth.sh` still
have some value, but are candidates for later collapse

This layer still enforces:

1. top-level script inventory
2. routing through `run-validation-gates.sh`
3. CI alignment to declared validation stages

That is still useful today.

But it is also a meta-layer. After the simpler removals below, re-evaluate whether:

1. the registry should remain a separate file
2. the source-of-truth check should be merged into a smaller contract script

This is not the first simplification target. It is a second-wave candidate.

## Non-Goals

This plan does not:

1. remove `hardware/host-descriptors.nix`
2. remove `new-host-skeleton.sh`
3. remove real host eval/build gates for `predator` or `aurelius`
4. remove public-safety checks
5. remove docs drift checks
6. remove useful fixture-diff tests for the host generator

## Success Criteria

The plan is successful when all of these are true:

1. `_migration-registry.nix` is gone
2. `modules/features/option-migrations.nix` is gone
3. no tracked host/template/fixture imports `option-migrations`
4. `scripts/check-option-migrations.sh` is gone
5. the option-migration lifecycle fixture is gone
6. `tests/scripts/ownership-boundary-fixture-test.sh` is gone or replaced by a
   real current boundary test
7. the test-pyramid synthetic fixtures are either:
   - removed, or
   - reduced to only what is still consumed by real validation contracts
8. all docs are updated to the post-migration, simplified validation model
9. `predator` system and HM closure diffs are empty for the migration-removal slice

## Execution Order

## Phase 0: Baseline Capture

Create a clean baseline before any simplification.

Commands:

```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh

nix build .#nixosConfigurations.predator.config.system.build.toplevel \
  -o /tmp/migration-removal-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path \
  -o /tmp/migration-removal-before-hm
```

Log in progress tracker:

1. current script/test inventory affected by the slice
2. current outputs for structure/predator/aurelius gates
3. baseline store paths

Commit:

None. Baseline only.

## Phase 1: Remove The Option-Migration Compatibility Stack

### Scope

Delete the live compatibility path completely.

Targets:

1. `modules/lib/_migration-registry.nix`
2. `modules/features/option-migrations.nix`
3. host imports in:
   - `modules/hosts/predator.nix`
   - `modules/hosts/aurelius.nix`
4. host skeleton templates and fixtures:
   - `templates/new-host-skeleton/*.tpl`
   - `tests/fixtures/new-host-skeleton/**`
5. docs that still teach or reference active option migrations:
   - `docs/for-agents/007-option-migrations.md`
   - `docs/for-agents/001-repo-map.md`
   - `docs/for-agents/002-den-architecture.md`
   - `docs/for-agents/003-module-ownership.md`
   - `docs/for-agents/005-validation-gates.md`
   - `docs/README.md`
   - relevant plan/progress docs if they describe it as live policy

### Expected Behavior Change

Tracked repo behavior should stay the same.

The only intended change is:

1. stale removed options will now fail with generic unknown-option errors instead of
   custom migration messages

### Validation

```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
bash tests/scripts/new-host-skeleton-fixture-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh

nix build .#nixosConfigurations.predator.config.system.build.toplevel \
  -o /tmp/migration-removal-after-phase1-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path \
  -o /tmp/migration-removal-after-phase1-hm

nix store diff-closures \
  /tmp/migration-removal-before-system \
  /tmp/migration-removal-after-phase1-system
nix store diff-closures \
  /tmp/migration-removal-before-hm \
  /tmp/migration-removal-after-phase1-hm
```

Diff expectation:

1. system diff empty
2. HM diff empty

Commit:

`refactor: remove finished option migration compatibility layer`

## Phase 2: Remove The Now-Dead Migration Gate And Fixture

### Scope

Delete the gate and all direct references that exist only to support it.

Targets:

1. `scripts/check-option-migrations.sh`
2. `tests/fixtures/option-migration-lifecycle/migration-registry.json`
3. references in:
   - `scripts/run-validation-gates.sh`
   - `tests/scripts/run-validation-gates-fixture-test.sh`
   - `tests/pyramid/shared-script-registry.tsv`
   - `tests/pyramid/config-test-pyramid.json`
   - docs that still list the gate

### Validation

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
bash scripts/check-changed-files-quality.sh
```

Diff expectation:

1. no predator or HM diff needed if no Nix code changed
2. validation runner structure output remains successful

Commit:

`refactor: remove obsolete option migration gate`

## Phase 3: Delete Stale Ownership Test

### Scope

Remove the current stale test unless it is rewritten to check a real modern rule.

Target:

1. `tests/scripts/ownership-boundary-fixture-test.sh`

Decision rule:

1. If no current gate or workflow consumes it, delete it.
2. Only keep it if it is rewritten in the same slice to protect a real current
   ownership boundary.

### Validation

```bash
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
```

Commit:

`test: remove stale ownership boundary fixture`

## Phase 4: Simplify The Synthetic Test-Pyramid Layer

### Scope

Remove or drastically reduce the meta-bookkeeping layer that validates synthetic
fixtures no real workflow consumes.

Primary targets:

1. `scripts/check-test-pyramid-contracts.sh`
2. `tests/pyramid/config-test-pyramid.json`
3. synthetic fixtures used only by that script:
   - `tests/fixtures/host-addition/host-descriptor.json`
   - `tests/fixtures/profile-addition/profile-metadata.json`
   - `tests/fixtures/pack-addition/pack-registry.json`
   - `tests/fixtures/pack-addition/synthetic-pack.nix`

Keep or re-home only the pieces that still have a real consumer:

1. `tests/pyramid/system-up-to-date-audit-decisions.tsv`
   - keep if audit still uses it
2. `tests/pyramid/shared-script-registry.tsv`
   - keep for now if `check-validation-source-of-truth.sh` still uses it

### Recommended Simplification Direction

Prefer this outcome:

1. delete `check-test-pyramid-contracts.sh`
2. delete `config-test-pyramid.json`
3. delete the synthetic category fixtures above
4. move any still-useful direct invariants into the script that actually consumes
   the data

Examples:

1. if the audit decision registry needs a header check, keep that near the audit
   contract, not in a generic pyramid script
2. if shared script registry stays, keep its checks in
   `check-validation-source-of-truth.sh`

### Validation

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
bash scripts/check-changed-files-quality.sh
```

Commit:

`refactor: remove synthetic test pyramid metadata layer`

## Phase 5: Remove The Redundant Full-Validation Wrapper

### Scope

If there is no meaningful consumer beyond the source-of-truth meta-check, remove:

1. `scripts/run-full-validation.sh`

Then simplify:

1. `scripts/check-validation-source-of-truth.sh`
2. `tests/pyramid/shared-script-registry.tsv`
3. docs that still mention `run-full-validation.sh`

### Validation

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
bash tests/scripts/gate-cli-contracts-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
```

Commit:

`refactor: remove redundant full validation wrapper`

## Phase 6: Re-evaluate The Remaining Validation Meta-Layer

This is a decision checkpoint, not an automatic deletion.

Re-evaluate:

1. `scripts/check-validation-source-of-truth.sh`
2. `tests/pyramid/shared-script-registry.tsv`

Questions:

1. Does the registry still prevent real drift that has happened before?
2. Is the script still smaller than the drift it prevents?
3. Can the same value be kept with a smaller single-source contract?

Possible outcomes:

1. keep as-is
2. shrink into a much smaller direct check
3. merge into another contract script

This phase should only be executed after Phases 1 through 5, so the decision is
made on the simplified repo, not the current noisier one.

## Docs To Update During The Plan

At minimum update:

1. `docs/for-agents/001-repo-map.md`
2. `docs/for-agents/005-validation-gates.md`
3. `docs/for-agents/007-option-migrations.md`
4. `docs/for-agents/999-lessons-learned.md`
5. relevant human docs if they still mention `option-migrations`
6. the current progress tracker for this plan

If the option-migration system is removed, `007-option-migrations.md` should either:

1. be deleted, or
2. be rewritten as a historical note

Deletion is preferred if no live process depends on it.

## Risks

### 1. Private stale config may lose friendly migration messages

This is expected and acceptable only if the team agrees the migration era is over.

### 2. Over-deleting validation meta-layers can silently lose useful guarantees

That is why the plan removes the migration stack first, then re-evaluates the
remaining meta-layer after the simpler dead pieces are gone.

### 3. Docs can drift badly during simplification

Every phase that changes gate structure must run:

```bash
./scripts/check-docs-drift.sh
```

## Recommended Commit Sequence

1. `refactor: remove finished option migration compatibility layer`
2. `refactor: remove obsolete option migration gate`
3. `test: remove stale ownership boundary fixture`
4. `refactor: remove synthetic test pyramid metadata layer`
5. `refactor: remove redundant full validation wrapper`
6. optional later decision commit for `check-validation-source-of-truth`

## Final Done Criteria

The simplification is done when:

1. the finished migration stack is fully gone
2. structure gates still pass
3. `predator` and `aurelius` validation gates still pass
4. `predator` system and HM closure diffs for the migration-removal slice are empty
5. docs no longer describe a live option-migration process
6. the remaining tests/scripts all protect a real current workflow or safety rule
