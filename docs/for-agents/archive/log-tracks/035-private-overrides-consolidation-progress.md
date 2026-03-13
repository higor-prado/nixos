# Private Overrides Consolidation Progress

## Status

Completed

## Related Plan

- [032-private-overrides-consolidation-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/032-private-overrides-consolidation-plan.md)

## Baseline

- User-private and host-private overrides started in different on-disk locations.
- The target was one top-level `private/` root with separate `users/` and `hosts/` subtrees.
- Existing real private files had to be moved so the repo could end with one canonical private layout.

## Slices

### Slice 1

- Created the active plan and matching progress log for consolidating private overrides under one top-level root.

Validation:
- scaffold/doc review only

Diff result:
- planning docs only

Commit:
- none

### Slice 2

- Updated tracked import points in [higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix), [default.nix](/home/higorprado/nixos/hardware/predator/default.nix), and [default.nix](/home/higorprado/nixos/hardware/aurelius/default.nix) to prefer `private/users/...` and `private/hosts/...`.
- Moved the real private files into the canonical `private/users/...` and `private/hosts/...` tree.
- Expanded [.gitignore](/home/higorprado/nixos/.gitignore) to cover the new private tree.
- Moved tracked example files into `private/users/...` and `private/hosts/...`.

Validation:
- `nix flake metadata path:$PWD`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Diff result:
- code, ignore rules, and tracked examples aligned with the new private tree

Commit:
- pending

### Slice 3

- Updated living agent docs and human docs to describe the unified private root and the new example paths.
- Normalized inline module comments so they no longer refer to the old flat `private.nix` wording.
- Removed the temporary fallback imports and deleted the old private paths so only the canonical tree remains.

Validation:
- living docs rechecked against the migrated import points
- `./scripts/check-docs-drift.sh`

Diff result:
- living docs and comments aligned with the migrated layout

Commit:
- pending

## Final State

- Tracked private override entry points now use one top-level `private/` root with `users/` and `hosts/` subtrees.
- Real private files now live only under the canonical `private/users/` and `private/hosts/` tree.
- Validation passed, including repo safety, docs drift, explicit predator eval/build checks, and the full validation gate script.
- Non-blocking warnings remained unchanged: `xorg.libxcb` deprecation and one validation path defaulting `system.stateVersion` to `26.05`.
