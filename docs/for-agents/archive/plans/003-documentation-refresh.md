# Documentation Refresh

## Goal

Refresh the repo's living documentation so it describes the current dendritic
runtime directly, while keeping migration history clearly bounded.

## Scope

In scope:
- living docs under `docs/for-humans/` and `docs/for-agents/`
- doc indexes and validation allowlists that still mention old runtime naming
- active tests/tooling descriptions that describe the old runtime incorrectly
- deciding which migration docs remain historical vs should be archived or renamed

Out of scope:
- rewriting archived migration logs for style
- changing active Nix runtime behavior
- deleting historical material that still has audit value

## Current State

- Canonical outputs now come from the repo-local dendritic runtime.
- No tracked active `.nix` files reference the removed runtime.
- Remaining migration references are concentrated in:
  - historical docs and migration logs
  - migration plans/logs under `docs/for-agents/plans/` and `docs/for-agents/current/`
  - a small number of living docs/tests/tooling descriptions
- Some root onboarding docs still point at stale names or stale descriptions.

## Desired End State

- Living docs explain the current repo in dendritic terms first.
- Historical migration material is clearly labeled and bounded.
- Tests/tooling descriptions no longer describe current behavior in removed-runtime terms.
- The remaining historical references are either:
  - intentionally historical, or
  - archived execution history.

## Phases

### Phase 0: Baseline

Targets:
- `docs/`
- `scripts/`
- `tests/`

Changes:
- Inventory the remaining tracked migration references.
- Classify each one as living, historical, or archival.

Validation:
- `rg -n "den|dendritic-without-den|002-den-architecture" docs scripts tests`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- no code or runtime changes

Commit target:
- none

### Phase 1: Refresh Living Docs

Targets:
- `docs/for-humans/*.md`
- `docs/for-agents/000-009*.md`
- `docs/README.md`

Changes:
- Rewrite living docs that still describe current behavior in stale
  pre-cutover terms.
- Replace stale file names and stale labels in the onboarding surface.
- Update wording so host composition, runtime context, and published lower-level
  modules are described directly in dendritic terms.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Diff expectation:
- doc-only diff

Commit target:
- `refactor(docs): refresh living dendritic docs`

### Phase 2: Align Tooling and Test Metadata

Targets:
- `tests/pyramid/*.tsv`
- `scripts/*`
- doc allowlists and registries

Changes:
- Update stale descriptions and comments that still imply removed-runtime
  semantics.
- Keep intentional historical references only where they are needed for
  indexing or public-safety allowlists.

Validation:
- `./scripts/run-validation-gates.sh`

Diff expectation:
- doc/script metadata only

Commit target:
- `refactor(tooling): align metadata with dendritic runtime`

### Phase 3: Bound Historical Material

Targets:
- architecture and migration-history docs
- active migration plan/log files

Changes:
- Decide whether any active migration docs should now move to archive.
- Tighten labels around historical docs so agents do not mistake them for
  canonical runtime guidance.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- doc moves / doc wording only

Commit target:
- `refactor(docs): bound historical migration material`

## Risks

- Over-cleaning could destroy useful migration context that still helps future
  audits.
- Under-cleaning leaves agents with conflicting guidance about the active
  runtime.
- Renaming or moving docs can break drift checks or allowlists if not updated in
  the same slice.

## Definition of Done

- Living docs describe the active repo as dendritic-first without stale
  removed-runtime language.
- Remaining historical references are clearly archived or intentionally
  bounded.
- Docs/tooling validation stays green.
