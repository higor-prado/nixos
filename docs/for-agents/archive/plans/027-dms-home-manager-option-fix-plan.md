# DMS Home Manager Option Fix

## Goal

Restore successful evaluation/build of the `predator` configuration by fixing the missing `home-manager.users.higorprado.programs.dank-material-shell` option after the recent den/Home Manager updates.

## Scope

In scope:
- diagnose the `programs.dank-material-shell` option registration path
- adjust tracked repo code under `modules/features/desktop/`
- validate the `predator` host eval/build path

Out of scope:
- changing private override files
- unrelated lockfile churn
- broader DMS feature redesign beyond restoring a correct den-native integration

## Current State

- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix) currently emits `home-manager.sharedModules` and `.homeManager.programs.dank-material-shell` from the same `take.exactly ({ host, user, ... }: ...)` include.
- [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix) already uses the expected split: host-level `home-manager.sharedModules`, user-level `.homeManager` config.
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) still imports `inputs.dms.nixosModules.dank-material-shell` and `inputs.dms.nixosModules.greeter`.
- The locked DMS input still declares `options.programs.dank-material-shell`, so the missing option likely comes from module registration/routing, not option removal.
- `~/git/den` was updated to `4bdcb63`, which matches the pinned `den` revision in [flake.lock](/home/higorprado/nixos/flake.lock).
- The previous pinned `den` revision in the worktree diff was `edaa0b0`; the only upstream `den` commit between `edaa0b0` and `4bdcb63` is `4bdcb63` from March 13, 2026: `feat(batteries): Opt-in den._.bidirectional (#272)`.
- Before `4bdcb63`, den's core OS pipeline invoked host aspects again with `{ host, user }` during user fan-out. After `4bdcb63`, that host-to-user reentry became opt-in through `den._.bidirectional`.
- Because [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix) places `home-manager.sharedModules` inside a host aspect include that requires `{ host, user }`, the DMS HM module stopped being registered at the NixOS level after the March 13 den update.
- That leaves `.homeManager.programs.dank-material-shell` config in place without the module that declares the option, producing the observed error under `home-manager.users.higorprado.programs.dank-material-shell`.

## Desired End State

- `home-manager.users.higorprado.programs.dank-material-shell` is declared before the DMS HM config is applied.
- `nix eval` and `nix build` for `predator` succeed again.
- The DMS feature follows the repo's den-native host/HM ownership pattern.
- The DMS feature uses the narrowest correct den context for each concern instead of relying on pre-March-13 implicit host `{ host, user }` behavior.

## Phases

### Phase 0: Baseline

Validation:
- capture the current failing error and affected files
- confirm the locked `den` and `dms` revisions from [flake.lock](/home/higorprado/nixos/flake.lock)

### Phase 1: Split host-level and user-level DMS wiring

Targets:
- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)

Changes:
- move `home-manager.sharedModules = [ host.inputs.dms.homeModules.dank-material-shell ];` into a host-only include
- keep greeter wiring and `programs.dsearch.enable` in the host-level NixOS include
- move the generic DMS Home Manager settings to host-owned `homeManager` config, because they apply equally to all HM users and do not require `user` context
- mirror the structural pattern used by [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix), but avoid unnecessary parametric HM wiring when owned host config is sufficient
- avoid relying on implicit host-aspect `{ host, user }` execution introduced by pre-`4bdcb63` den behavior
- use parametric includes only where host data is genuinely required

Validation:
- `nix flake metadata`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- one focused diff in the DMS feature module only
- no changes to host composition or private files
- less context-coupled code than the current shape

Commit target:
- `fix(dms): register hm module before dms hm config`

### Phase 2: Full host validation

Targets:
- repo validation commands only

Changes:
- no further code changes unless validation exposes a second issue

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh`
- optional: `nix run nixpkgs#nvd -- diff /tmp/predator-baseline /tmp/predator-new`

Diff expectation:
- successful eval/build with no reintroduced missing-option failure

Commit target:
- none if Phase 1 is sufficient

## Risks

- the current failure may be compounded by the simultaneous `flake.lock` updates to `dms`, `home-manager`, and `den`
- local validation may require unsandboxed access to the Nix daemon
- DMS upstream may have behavior changes that only appear after the missing-option issue is fixed
- if any other host aspect now relies on pre-March-13 implicit `{ host, user }` execution, the DMS fix may expose additional den-compatibility cleanups

## Definition of Done

- the active plan reflects the chosen repair approach
- DMS module wiring is corrected in tracked files
- the `predator` Home Manager path and system toplevel build validate successfully
- any remaining blocker is narrowed to a specific follow-up issue with evidence
- the final DMS structure is defensible against den's current context model: host-only NixOS concerns stay in host context, and generic host-owned HM concerns are expressed as host `homeManager` config rather than accidental user-shaped host includes
