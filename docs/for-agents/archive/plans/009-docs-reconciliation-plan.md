# Docs Reconciliation Plan

Status: planned

## Goal

Reconcile the living documentation with the current repository state after the
recent simplification and helper-location refactors.

This plan focuses on making the docs trustworthy again for current operators and
agents.

## Scope

In scope:

1. living docs in:
   - `README.md`
   - `AGENTS.md`
   - `docs/README.md`
   - `docs/for-agents/000-009, 999`
   - `docs/for-humans/00-05`
   - `docs/for-humans/workflows/*`
2. any `docs/for-agents/current/*` file that claims current repo state and now
   contradicts the live tree

Out of scope:

1. historical plan docs that are clearly historical
2. old progress logs that only describe past changes accurately in historical tense
3. changing repo code or validation behavior unless a docs fix uncovers a real repo
   inconsistency

## Audit Findings

### 1. `docs/for-agents/001-repo-map.md` is stale

Current issues:

1. top-level layout still says:
   - `modules/lib/        shared helpers (_helpers.nix, _starship-settings.nix, den-host-context.nix)`
2. that is wrong now:
   - `_starship-settings.nix` lives under `modules/features/`
   - `_helpers.nix` lives under root `lib/`
   - `modules/lib/` only contains `den-host-context.nix`
3. `home/base/` description was only partially updated and should clearly say it
   now holds private overrides, not shared helper code

### 2. `docs/for-agents/002-den-architecture.md` likely needs a consistency pass

Current state:

1. it correctly explains `_starship-settings.nix` as an underscored feature-private
   file under `modules/`
2. it already reflects the move of `mutable-copy.nix` to root `lib/`

Action:

1. verify all snippets and directory descriptions still match the live tree
2. especially confirm host composition examples and `home/base/` wording

### 3. `docs/for-agents/005-validation-gates.md` was simplified, but needs a final
consistency pass

Current state:

1. wrapper and migration gate language was updated
2. the registry/source-of-truth layer still exists and is intentional

Action:

1. verify script/category descriptions still match the actual registry
2. verify the listed “individual gate scripts” match what `run-validation-gates.sh`
   really calls now

### 4. `README.md` and `docs/for-humans/02-structure.md` need a fresh structure
pass

Current state:

1. `README.md` was updated for `lib/`, but should be checked for other stale
   structure language
2. `docs/for-humans/02-structure.md` mentions `_starship-settings.nix` correctly
   as an underscored skipped file, but should be checked for any remaining stale
   `home/base/` or validation references

### 5. `AGENTS.md` likely still works, but should be checked for now-retired live
procedures

Current state:

1. it still points to `docs/for-agents/007-option-migrations.md`
2. that document now exists as a historical note, so this is acceptable

Action:

1. confirm AGENTS does not imply option-migration is an active workflow

### 6. `docs/for-agents/current/*` should be split into two buckets

Bucket A: keep as-is

1. logs that are historical and clearly describe what happened at the time

Bucket B: normalize or close

1. files that claim current repo state but still refer to removed live surfaces as if
   they are active

Likely review targets:

1. `docs/for-agents/current/003-antipattern-diag.md`
2. `docs/for-agents/current/004-antipattern-priority-order.md`
3. `docs/for-agents/current/010-option-migration-removal-and-validation-simplification-progress.md`

The goal is not to erase history. The goal is to avoid current-state docs lying.

## Success Criteria

The docs cleanup is done when:

1. all living docs describe the current tree accurately
2. no living doc points to removed live files as if they still exist
3. no living doc misplaces `_starship-settings.nix`, `_helpers.nix`, or
   `mutable-copy.nix`
4. validation docs describe the current post-simplification gate structure
5. any `current/` doc that claims present state does not contradict the repo
6. `./scripts/check-docs-drift.sh` passes

## Execution Order

## Phase 0: Baseline And Classification

Review and classify docs into:

1. living docs
2. historical docs
3. current-state logs needing reconciliation

Commands:

```bash
./scripts/check-docs-drift.sh
rg -n "_starship-settings|home/base/lib|option-migrations|run-full-validation|check-test-pyramid|server-example|new-host" docs README.md AGENTS.md
```

Commit:

None.

## Phase 1: Fix Structure And Location Docs

Targets:

1. `README.md`
2. `docs/README.md`
3. `docs/for-humans/02-structure.md`
4. `docs/for-agents/001-repo-map.md`
5. `docs/for-agents/002-den-architecture.md`

Primary goals:

1. correct ownership/location of:
   - `lib/_helpers.nix`
   - `lib/mutable-copy.nix`
   - `modules/features/_starship-settings.nix`
   - `modules/lib/den-host-context.nix`
2. ensure `home/base/` is described only as private overrides, not shared helper
   storage

Validation:

```bash
./scripts/check-docs-drift.sh
```

Commit:

`docs: reconcile structure docs with current tree`

## Phase 2: Fix Validation And Workflow Docs

Targets:

1. `docs/for-agents/005-validation-gates.md`
2. `docs/for-humans/workflows/101-switch-and-rollback.md`
3. `docs/for-humans/workflows/103-add-host.md`
4. `docs/for-humans/workflows/106-deploy-aurelius.md`
5. any other workflow doc found to mention removed validation machinery

Primary goals:

1. remove wording that implies:
   - active option-migration gate
   - active synthetic test-pyramid layer
   - active `run-full-validation.sh`
2. ensure workflows mention the current gate runner and current generator behavior

Validation:

```bash
./scripts/check-docs-drift.sh
```

Commit:

`docs: reconcile validation and workflow docs`

## Phase 3: Reconcile Current-State Agent Docs

Targets:

1. `docs/for-agents/current/003-antipattern-diag.md`
2. `docs/for-agents/current/004-antipattern-priority-order.md`
3. `docs/for-agents/current/010-option-migration-removal-and-validation-simplification-progress.md`
4. any other `current/` file discovered to present stale live state

Rules:

1. preserve historical context where useful
2. rewrite present-tense claims that are now false
3. add explicit “historical note” wording where needed instead of deleting context

Validation:

```bash
./scripts/check-docs-drift.sh
```

Commit:

`docs: normalize current-state agent notes`

## Phase 4: Final Verification

Commands:

```bash
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
```

Optional:

```bash
./scripts/run-validation-gates.sh structure
```

Commit:

Only if final cleanups are still pending.

## Risks

### 1. Over-editing historical docs

Avoid rewriting old plan/progress files that are clearly historical unless they are
presenting false current-state guidance.

### 2. Fixing only path names but not semantics

A doc can pass `check-docs-drift.sh` and still be wrong conceptually. Every phase
must be reviewed for semantic truth, not just path existence.

### 3. Reintroducing doc sprawl

Prefer updating the authoritative living docs rather than sprinkling corrections
across many progress logs.

## Recommended Outcome

After this plan:

1. living docs are reliable again
2. historical docs remain useful but clearly historical
3. operators and future agents can trust the current structure/validation docs
   without needing to reconstruct recent refactors from Git history
