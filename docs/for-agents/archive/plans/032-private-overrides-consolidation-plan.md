# Private Overrides Consolidation

## Goal

Consolidate private overrides into one top-level `private/` tree so all private material lives in one place for humans, while preserving clear ownership boundaries between user-private and host-private configuration.

## Scope

In scope:
- define a single top-level private layout for users and hosts
- update tracked import points to load private files from that unified layout
- update tracked examples and living docs that describe the private override contract
- preserve correct private override behavior after migration

Out of scope:
- redesigning the public/private policy itself
- unrelated feature/module refactors

## Baseline State

- User-private overrides started under the top-level [private/](/home/higorprado/nixos/private) area and were imported by [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix).
- Host-private overrides started under per-host hardware paths such as [hardware/predator/private.nix](/home/higorprado/nixos/hardware/predator/private.nix) and [hardware/predator/private/](/home/higorprado/nixos/hardware/predator/private), imported by [hardware/predator/default.nix](/home/higorprado/nixos/hardware/predator/default.nix) and [hardware/aurelius/default.nix](/home/higorprado/nixos/hardware/aurelius/default.nix).
- This split works, but private material is not discoverable from one obvious root.
- The repo’s docs and safety rules currently describe the older split.

## Desired End State

- All private overrides live under one top-level private root:
  - `private/users/<user>/...`
  - `private/hosts/<host>/...`
- Tracked import points remain near the public owners, but they import from the unified private root.
- Tracked example files and docs explain the unified layout clearly.
- Public-safety and validation checks remain green.

## Phases

### Phase 0: Baseline

Validation:
- inventory current tracked import points for user-private and host-private config
- inventory tracked example files and docs describing private overrides
- identify any existing gitignore patterns that must change

### Phase 1: Introduce Unified Private Layout

Targets:
- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
- [hardware/predator/default.nix](/home/higorprado/nixos/hardware/predator/default.nix)
- [hardware/aurelius/default.nix](/home/higorprado/nixos/hardware/aurelius/default.nix)
- tracked `*.example` files for host/user private entry points
- repo ignore rules if needed

Changes:
- switch tracked import points to a unified `private/users/...` and `private/hosts/...` layout
- keep the import behavior optional with `builtins.pathExists`
- add or move tracked `*.example` files so the new layout is documented by example
- move any existing real private files into the canonical tree so the repo ends with one actual layout

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- tracked import paths point at the unified private tree
- examples and ignore rules reflect the new structure

Commit target:
- `refactor(private): consolidate override paths`

### Phase 2: Update Docs and Contracts

Targets:
- [docs/for-agents/001-repo-map.md](/home/higorprado/nixos/docs/for-agents/001-repo-map.md)
- [docs/for-agents/003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md)
- [docs/for-agents/004-private-safety.md](/home/higorprado/nixos/docs/for-agents/004-private-safety.md)
- any tracked human-facing private override docs still describing the old split

Changes:
- rewrite docs so they describe one top-level private root with `users/` and `hosts/` subtrees
- keep the ownership explanation explicit: one place for humans, structured subtrees for code ownership
- update any path examples that still point to `hardware/<host>/private*.nix`

Validation:
- `./scripts/check-docs-drift.sh`
- quick manual reread against the actual import paths

Diff expectation:
- docs-only follow-up aligned with the new private layout

Commit target:
- `docs(private): document unified override layout`

### Phase 3: Final Validation and Closeout

Targets:
- touched files only

Changes:
- no further functional changes unless validation exposes a follow-up issue
- update the progress log with actual migration details and residual risks

Validation:
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- only the intended private-layout migration changes remain

Commit target:
- none if earlier slices are committed separately

## Risks

- migrating import paths can break local private overrides if the real files are not moved into the canonical tree
- ignore rules must continue to protect real private files after the move
- docs and examples can drift if the old and new layouts coexist for too long

## Execution Notes

- Tracked import points now use `private/users/...` and `private/hosts/...`.
- Existing real private files were moved into the canonical tree.
- Legacy private paths were removed so the repo ends with one real private layout.

## Definition of Done

- all tracked private override entry points use the unified top-level `private/` tree
- the new layout separates `users/` and `hosts/` clearly
- tracked examples and docs match the new layout
- safety and validation checks pass after the migration

## Execution Notes

- Tracked import points now prefer `private/users/...` and `private/hosts/...`.
- Legacy private paths remain as temporary compatibility fallbacks so existing local machines do not break during migration.
