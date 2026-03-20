# Documentation Refresh After Den Removal

## Goal

Refresh the repo's living documentation so it describes the current dendritic
runtime directly, while keeping `den` material only where it is intentionally
historical or migration-related.

## Scope

In scope:
- living docs under `docs/for-humans/` and `docs/for-agents/`
- doc indexes and validation allowlists that still mention `den`
- active tests/tooling descriptions that describe the old runtime incorrectly
- deciding which `den` docs remain historical vs should be archived or renamed

Out of scope:
- rewriting archived migration logs for style
- changing active Nix runtime behavior
- deleting historical material that still has audit value

## Current State

- Canonical outputs now come from the repo-local dendritic runtime.
- No tracked active `.nix` files reference `den`.
- Remaining `den` references are concentrated in:
  - historical docs such as `docs/for-agents/002-den-architecture.md`
  - migration plans/logs under `docs/for-agents/plans/` and `docs/for-agents/current/`
  - a small number of living docs/tests/tooling descriptions
- `docs/README.md` still intentionally indexes `002-den-architecture.md` as a
  historical document.

## Desired End State

- Living docs explain the current repo in dendritic terms first.
- Historical `den` material is clearly labeled and bounded.
- Tests/tooling descriptions no longer describe current behavior in `den` terms.
- The remaining `den` references are either:
  - intentionally historical, or
  - archived execution history.

## Phases

### Phase 0: Baseline

Targets:
- `docs/`
- `scripts/`
- `tests/`

Changes:
- Inventory the remaining tracked `den` references.
- Classify each one as living, historical, or archival.

Validation:
- `rg -n "\\bden\\b" docs scripts tests`
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
- Rewrite living docs that still describe current behavior in `den` terms.
- Keep `002-den-architecture.md` historical unless there is a strong reason to
  split or archive it now.
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
- Update stale descriptions and comments that still imply active `den`
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
- `docs/for-agents/002-den-architecture.md`
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
- `refactor(docs): bound historical den material`

## Risks

- Over-cleaning could destroy useful migration context that still helps future
  audits.
- Under-cleaning leaves agents with conflicting guidance about the active
  runtime.
- Renaming or moving docs can break drift checks or allowlists if not updated in
  the same slice.

## Definition of Done

- Living docs describe the active repo as dendritic-first without stale `den`
  runtime language.
- Remaining `den` references are clearly historical or archived.
- Docs/tooling validation stays green.
