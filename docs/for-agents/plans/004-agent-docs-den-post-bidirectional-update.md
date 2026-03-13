# Agent Docs Den Post-Bidirectional Update

## Goal

Update the repo's active agent docs so they teach den's current post-March-13, 2026 model: explicit bidirectionality, current Home Manager integration ownership, and narrower host-aware HM context examples.

## Scope

In scope:
- active agent docs under `docs/for-agents/`
- durable architectural guidance and examples
- lessons-learned entries if the new guidance is important enough to preserve as an operating rule

Out of scope:
- archived docs
- further feature-code refactors
- upstream den docs or code

## Current State

- [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md) still describes HM integration using the removed upstream `hm-os` / `hm-integration` file split.
- [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md) still shows host-aware HM examples using `{ host, user, ... }` where the new repo guidance should prefer `{ host, ... }` unless `user` is genuinely required.
- [006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md) still uses a feature-with-home-manager example that mixes `nixos` and `homeManager` in a `{ host, user, ... }` shape.
- [999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md) does not yet record the March 13 den shift explicitly.

## Desired End State

- Active agent docs no longer teach the old HM integration internals.
- Examples match the narrowed repo guidance:
  - owned `homeManager` when no host/user data is needed
  - `{ host, ... }` for host-aware HM config
  - `{ host, user, ... }` only for real user-specific logic
- The March 13 den shift is preserved as a lesson so future refactors do not accidentally reintroduce pre-change assumptions.

## Phases

### Phase 0: Baseline

Validation:
- confirm all stale references in active docs
- capture the exact replacement guidance from the current repo state and den code/tests

### Phase 1: Update Active Architecture Docs

Targets:
- [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md)
- [006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md)

Changes:
- replace the obsolete `hm-os` / `hm-integration` description with the current `home-manager.nix` integration shape
- update host-aware HM examples to use the narrowest correct context
- add a short note that host-to-user OS reentry is now explicit via `den._.bidirectional`, not implicit

Validation:
- `./scripts/check-docs-drift.sh`
- quick manual reread of the updated examples against current repo modules

Diff expectation:
- docs-only change
- clearer examples that match current tracked code

Commit target:
- `docs(agents): update den guidance after bidirectional change`

### Phase 2: Record Durable Lesson

Targets:
- [999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md)

Changes:
- add one short lesson capturing the post-March-13 den rule:
  - host `{ host, user }` OS flow is explicit/opt-in
  - use the narrowest context shape for HM and NixOS concerns

Validation:
- `./scripts/check-docs-drift.sh`

Diff expectation:
- one concise lesson entry, not a long narrative

Commit target:
- `docs(agents): record den context-width lesson`

## Risks

- docs can drift again if they describe upstream internal filenames instead of behavior
- over-explaining the upstream change could make the active docs noisier than needed

## Definition of Done

- active agent docs reflect den's current post-bidirectional model
- stale upstream file-path references are gone from active docs
- examples guide future edits toward the same narrowed context shapes now used in tracked code
