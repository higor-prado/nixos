# Agent Docs Archive And Reconciliation Plan

## Goal

Reduce noise in `docs/for-agents/`, archive closed work cleanly, refresh the
scaffolding agents should use for future plans/log tracks, and remove stale
guidance that no longer matches the current repo architecture.

## Scope

In scope:
- archive structure for completed plans/log tracks
- scaffolds for future plan and progress docs
- pruning outdated entries from `999-lessons-learned.md`
- reconciling stale agent and human docs with the current repo

Out of scope:
- changing repo architecture
- rewriting all historical docs into present-tense summaries
- removing valuable historical records that should simply be archived

## Current State

Structural facts:
- active plans live in `docs/for-agents/plans/`
- active progress logs live in `docs/for-agents/current/`
- there was no archive surface for closed plan/progress docs
- there was no tracked scaffold for how plans and logs should be written

Concrete drift found during analysis:
- `docs/for-agents/999-lessons-learned.md` still contains lessons tied to
  removed architecture, especially:
  - migration-registry / option-migration workflow lessons
  - legacy parity/audit script guidance
  - older numbering guidance for `docs/for-agents`
- `docs/for-agents/001-repo-map.md` still presents an `AI` feature bucket even
  though the repo now uses `dev/llm-agents.nix`
- some historical/current docs still mention removed surfaces such as
  `core-options`, example hosts, `ops`, and old validation layers
- `docs/for-humans/workflows/103-add-host.md` still includes stale
  `llmAgentsPkgs` wording from the older semantic-host-selection transition

## Desired End State

- closed plans can be archived under `docs/for-agents/archive/plans/`
- closed progress logs can be archived under
  `docs/for-agents/archive/log-tracks/`
- agents have a simple scaffold for new plan/progress docs
- `999-lessons-learned.md` contains only lessons still relevant to the current
  repo architecture and workflow
- living docs match the current repo surface and no longer teach removed shapes

## Phases

### Phase 0: Archive Surface And Scaffolds

Status:
- already created in this slice

Created:
- `docs/for-agents/archive/plans/`
- `docs/for-agents/archive/log-tracks/`
- `docs/for-agents/plans/000-plan-scaffold.md`
- `docs/for-agents/current/000-log-track-scaffold.md`

Validation:
- `./scripts/check-docs-drift.sh`

### Phase 1: Prune Outdated Lessons

Targets:
- `docs/for-agents/999-lessons-learned.md`

Likely removals or rewrites:
- lessons that require a migration-registry or option-migration compatibility
  workflow that no longer exists
- lessons that describe removed parity/audit script families as if they were a
  live repo norm
- lessons that encode obsolete `docs/for-agents` numbering policy
- lessons that only describe transitional cleanup work already fully retired

Keep:
- den-native architecture lessons
- ownership/boundary rules still enforced by the repo
- build/runtime validation lessons that still apply
- lessons that remain useful because the repo still has the relevant mechanism

Validation:
- `./scripts/check-docs-drift.sh`
- targeted `rg` to confirm removed concepts no longer appear in `999` unless
  intentionally historical

Commit target:
- `docs: prune outdated lessons learned`

### Phase 2: Reconcile Living Agent Docs

Targets:
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/007-option-migrations.md`
- `docs/for-agents/999-lessons-learned.md`
- selected files in `docs/for-agents/current/`

Focus:
- update repo-map category descriptions to match the current feature layout
- ensure validation docs reflect the current script surface
- keep `007-option-migrations.md` explicitly historical and bounded
- identify active `current/` logs that should stay active vs move to archive

Validation:
- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`

Commit target:
- `docs: reconcile living agent docs with current repo`

### Phase 3: Reconcile Human Docs

Targets:
- `docs/for-humans/01-philosophy.md`
- `docs/for-humans/02-structure.md`
- `docs/for-humans/03-multi-host.md`
- `docs/for-humans/workflows/102-add-feature.md`
- `docs/for-humans/workflows/103-add-host.md`
- `docs/for-humans/workflows/104-add-desktop-experience.md`

Known checks:
- remove stale `llmAgentsPkgs` wording
- ensure feature-group descriptions reflect the current `modules/features/*`
  layout
- confirm host workflow still matches `new-host-skeleton.sh`

Validation:
- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`

Commit target:
- `docs: reconcile human docs with current repo`

### Phase 4: Archive Closed Records

Selection rule:
- keep active only:
  - durable diagnostics still used as a current operating surface
  - plans that are genuinely pending
  - progress logs for work still in progress or still serving as active state
- archive:
  - completed plans whose guidance is purely historical
  - completed progress logs that no longer need to live in the active surface

Initial likely archive candidates:
- early completed cleanup/refactor plans and their matching progress logs
- logs that only describe already-completed migrations with no remaining open
  state

Targets:
- move selected files from:
  - `docs/for-agents/plans/`
  - `docs/for-agents/current/`
- into:
  - `docs/for-agents/archive/plans/`
  - `docs/for-agents/archive/log-tracks/`

Validation:
- `./scripts/check-docs-drift.sh`
- update any living references to archived files, or stop linking them from the
  living surface if they are meant to be purely archival

Commit target:
- `docs: archive closed agent plans and logs`

## Risks

- Over-archiving can hide context still useful for future agents.
- Under-archiving leaves the active surface noisy and harder to navigate.
- `999-lessons-learned.md` can lose useful constraints if pruning is too
  aggressive.

## Definition of Done

- archive folders exist and are tracked
- plan/progress scaffolds exist
- `999-lessons-learned.md` no longer teaches removed architecture as if active
- living docs match the current repo
- stale completed plan/progress docs are archived out of the active surface

