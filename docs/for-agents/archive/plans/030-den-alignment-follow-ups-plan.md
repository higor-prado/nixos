# Den Alignment Follow-ups

## Goal

Bring the repo back in line with the current local `den` patterns identified in the alignment report by fixing the `linuwu_sense` user-group wiring on `predator` and narrowing the living agent-doc guidance so it teaches the smallest correct den context shape.

## Scope

In scope:
- fix the tracked `linuwu_sense` membership wiring for `predator`
- update the two living agent docs that currently over-prefer `{ host, user }`
- validate the resulting NixOS/Home Manager outputs and docs drift

Out of scope:
- broad stylistic refactors from explicit `den.lib.parametric` wrappers to newer auto-parametric style
- changing the `custom.user.name` compatibility bridge
- archive-only doc rewrites beyond what is needed for this active follow-up

## Current State

- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) contains an inline include intended to add `linuwu_sense` to the tracked user’s `extraGroups`.
- On this machine, `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups` returned `["wheel","networkmanager"]`, so the tracked `linuwu_sense` intent is not currently visible in the evaluated result.
- [docs/for-agents/000-operating-rules.md](/home/higorprado/nixos/docs/for-agents/000-operating-rules.md) and [docs/for-agents/003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md) still say to prefer den `{ host, user }` context, even though the repo’s newer den guidance now prefers the narrowest correct context shape.
- The alignment findings are documented in [032-den-pattern-alignment-report.md](/home/higorprado/nixos/docs/for-agents/archive/log-tracks/032-den-pattern-alignment-report.md).

## Desired End State

- `predator` evaluates with the intended `linuwu_sense` membership present for the tracked user.
- The group-wiring shape is defensible against current den host/user pipeline semantics.
- Living agent docs tell future edits to prefer the narrowest correct den context shape:
  - owned `homeManager` when no host/user data is needed
  - `{ host }` when only host data is needed
  - `{ host, user }` only when the logic is genuinely user-specific
- Repo validation and docs drift checks stay green.

## Phases

### Phase 0: Baseline

Validation:
- confirm the current evaluated `predator` user group list
- inspect the relevant `den` local examples/tests that justify the replacement shape
- capture the current doc wording in the two living files

### Phase 1: Fix `linuwu_sense` User Wiring

Targets:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- possibly one new or existing tracked feature/helper module under [modules/features/](/home/higorprado/nixos/modules/features)

Changes:
- replace the current ineffective inline host include with an explicit user-context-safe shape
- prefer a den pattern that matches current upstream examples for user-scoped OS contributions
- keep the behavior focused on `predator` unless a more reusable owner is clearly warranted

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- if the evaluated closure changes materially: `nix store diff-closures <baseline> <candidate>`

Diff expectation:
- one focused change to the `predator` user-group wiring
- evaluated `extraGroups` now include `"linuwu_sense"`

Commit target:
- `fix(predator): restore linuwu_sense user group wiring`

### Phase 2: Correct Living Agent Guidance

Targets:
- [docs/for-agents/000-operating-rules.md](/home/higorprado/nixos/docs/for-agents/000-operating-rules.md)
- [docs/for-agents/003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md)

Changes:
- replace the generic “prefer `{ host, user }`” wording with “prefer the narrowest correct den context shape”
- keep `custom.user.name` framed as compatibility-only
- keep the guidance aligned with the newer den guidance already reflected in the repo’s other living docs

Validation:
- `./scripts/check-docs-drift.sh`
- targeted reread against the den alignment report and current den docs/tests

Diff expectation:
- docs-only wording change in two living agent docs
- no archive churn

Commit target:
- `docs(agents): narrow den context guidance`

### Phase 3: Final Validation and Closeout

Targets:
- touched files only

Changes:
- no further functional changes unless validation exposes a follow-up issue
- update the active progress log with validation outcomes and residual risks

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- only the intended code/docs follow-up changes remain

Commit target:
- none if earlier slices are already committed separately

## Risks

- the `linuwu_sense` membership may be failing due to a more subtle merge/owner interaction than just context width
- moving the group wiring into a different owner may uncover an older assumption in archived notes or hardware comments
- docs wording can accidentally become too abstract; it should stay concrete enough for future edits

## Definition of Done

- `predator`’s tracked user evaluates with `linuwu_sense` in `extraGroups`
- the final implementation uses a den pattern that matches current upstream semantics for user-scoped OS config
- the two living agent docs no longer over-prefer `{ host, user }`
- public-safety, docs-drift, and validation gates pass after the changes
- the active progress log records the baseline, slices, validation, and any residual follow-up
