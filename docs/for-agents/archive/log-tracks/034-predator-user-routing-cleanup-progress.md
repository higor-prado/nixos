# Predator User Routing Cleanup Progress

## Status

Completed

## Related Plan

- [031-predator-user-routing-cleanup-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/031-predator-user-routing-cleanup-plan.md)

## Baseline

- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix) currently uses `if host.name == "predator"` for `predator`-specific user-group wiring.
- That workaround needs to be replaced with an explicit den-native routing pattern.
- No cleanup has been applied for this plan yet.

## Slices

### Slice 1

- Created the active plan and matching progress log for removing the `predator` host-name conditional workaround.

Validation:
- scaffold/doc review only

Diff result:
- planning docs only

Commit:
- pending

### Slice 2

- Replaced the `if host.name == "predator"` workaround in [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix) with an explicit den route:
  - added `den._.mutual-provider` to the user aspect includes
  - moved the `predator`-specific group contribution into `provides.predator`
- Kept the contribution scoped to the `higorprado`/`predator` pair instead of broadening it globally.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- the tracked workaround is gone
- `predator` still evaluates with:
  - `["wheel","networkmanager","video","audio","input","docker","rfkill","uinput","linuwu_sense"]`

Commit:
- pending

### Slice 3

- Ran final validation after the routing cleanup.

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Diff result:
- cleanup validated successfully
- non-blocking warnings remained the same:
  - `xorg.libxcb` deprecation warning
  - existing `system.stateVersion` warning on one validation path

Commit:
- pending

## Final State

- The ugly `if host.name == "predator"` workaround is gone.
- `predator`-specific user-group wiring is now expressed through explicit den routing with `provides.predator` and `den._.mutual-provider`.
- `predator` still evaluates and builds with the intended group set.
- Public-safety, docs-drift, and the full validation gate runner passed after the refactor.
