# Den Mutual Routing Doc Alignment

## Goal

Confirm that the post-bidirectional migration follows the current `den`
philosophy and public API, then update the repo documentation so it teaches the
correct host-to-user Home Manager routing model.

## Scope

In scope:
- verify the exact current `den` behavior from pinned upstream sources
- tighten the tracked repo to the most idiomatic `den` shape when needed
- update durable agent docs to describe the new routing model correctly
- explain the final model in repo terms

Out of scope:
- unrelated flake input updates
- new feature work unrelated to host<->user mutual routing
- private overrides

## Current State

- The tracked repo now works without `den._.bidirectional`.
- The migration was validated functionally, but durable docs still describe the
  old assumption that host-owned feature `.homeManager` is routed automatically.
- Upstream `den` public docs describe the mutual API in terms of
  `provides.to-users` / `provides.to-hosts`, while the implementation consumes
  the internal `._.to-users` / `._.to-hosts` namespace.

## Desired End State

- The repo uses the most correct and idiomatic public `den` API for declaring
  host-to-user and user-to-host contributions.
- Agent docs explain:
  - unidirectional vs mutual routing
  - when plain `.homeManager` is correct
  - when host-owned HM must go through mutual routing
  - why host aspects aggregate child `to-users` projections explicitly
- The explanation aligns with the `den` version actually pinned by this repo.

## Phases

### Phase 0: Source-of-Truth Audit

Targets:
- pinned `den` store path
- repo migration diff
- durable agent docs that mention `.homeManager`, `bidirectional`, or feature patterns

Changes:
- no tracked edits required

Validation:
- inspect pinned `den` docs, source, and CI templates
- identify any remaining repo style mismatch against public `den` API

### Phase 1: Idiom Alignment

Targets:
- tracked feature/desktop modules if style corrections are justified
- tracked host/composition modules if aggregation shape needs tightening

Changes:
- prefer public `provides.to-users` declarations where that is the documented
  author-facing API
- keep host-side aggregation on the namespace actually consumed by
  `den._.mutual-provider`

Validation:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Phase 2: Documentation Update

Targets:
- durable agent docs in `docs/for-agents/`
- active progress log for this task

Changes:
- update repo docs to reflect current `den` philosophy and routing model
- add a lesson if this work surfaced a durable operating rule

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh all`

## Risks

- overfitting docs to an internal implementation detail instead of the public API
- leaving mixed terminology (`homeManager`, `provides.to-users`, `_.to-users`)
  unexplained, which would make the repo harder to maintain later
- performing style-only changes that do not improve clarity

## Definition of Done

- the repo’s post-bidirectional shape is confirmed against pinned upstream `den`
- any justified idiom cleanup is applied and validated
- durable docs no longer teach the removed/obsolete routing model
- the final explanation is precise enough to justify the code shape
