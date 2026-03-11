# DMS HM Migration Plan

## Goal

Repair `predator` desktop startup by moving the tracked `dms` ownership toward
the upstream-supported Home Manager path, while keeping the custom
`dms-awww` wallpaper integration clearly separate.

## Scope

In scope:
- `modules/features/desktop/dms.nix`
- `modules/features/desktop/dms-wallpaper.nix`
- `predator` runtime validation
- preserving the split between official `dms` and custom `dms-awww`

Out of scope:
- disk / `@persist` activation work
- `aurelius`
- changing DMS functionality beyond startup/runtime ownership
- redesigning the custom `dms-awww` package

## Current State

- Upstream `dms` Home Manager module:
  - enables `programs.quickshell`
  - installs the DMS runtime packages in `home.packages`
  - owns `systemd.user.services.dms`
  - writes `settings.json`, `session.json`, and plugin settings
- Upstream `dms` NixOS module also defines `systemd.user.services.dms`, but it
  clears the service `path`.
- The repo currently owns `dms` from the NixOS side in
  [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix).
- `dms-awww` is a separate custom integration in
  [modules/features/desktop/dms-wallpaper.nix](/home/higorprado/nixos/modules/features/desktop/dms-wallpaper.nix).
- Boot logs previously showed:
  - `dms.service`: `qs` not found in `$PATH`
  - `dms-awww.service`: `awww` not found in `$PATH`
  - later `dms-awww`: write failure under `~/.config/DankMaterialShell`

## Desired End State

- `dms` follows the upstream HM ownership path for user runtime.
- NixOS-side DMS config is limited to the system concerns that truly belong
  there.
- `dms-awww` remains separate and is fixed only after `dms` startup is clean.
- `predator` can log into Niri and bring up DMS without manual intervention.

## Phases

### Phase 0: Baseline capture

Targets:
- current `predator` DMS wiring

Changes:
- capture the exact repo-vs-upstream ownership mismatch
- record the runtime failures already observed

Validation:
- `./scripts/check-docs-drift.sh`

Diff expectation:
- none

Commit target:
- docs-only if needed

### Phase 1: Move official DMS ownership to HM

Targets:
- `modules/features/desktop/dms.nix`

Changes:
- stop hand-owning DMS runtime from the NixOS side
- re-express the tracked DMS config through the den `.homeManager` class so it
  follows the upstream HM ownership model
- keep only genuinely system/greeter concerns on the NixOS side

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- inspect evaluated HM `systemd.user.services.dms`

Diff expectation:
- closure changes limited to DMS user runtime ownership

Commit target:
- `refactor(dms): move official runtime ownership to hm`

### Phase 2: Re-test DMS alone on Predator

Targets:
- live `predator` only

Changes:
- apply only the DMS ownership migration
- do not combine this with disk/persist activation

Validation:
- `nh os test path:$PWD`
- `systemctl --user status dms.service --no-pager`
- `journalctl --user -b --no-pager | rg "dms|qs"`

Diff expectation:
- DMS autostarts cleanly

Commit target:
- record runtime result in progress log only

### Phase 3: Fix custom DMS wallpaper integration

Targets:
- `modules/features/desktop/dms-wallpaper.nix`

Changes:
- fix the custom `dms-awww` runtime independently from DMS
- address:
  - access to `awww`
  - access to `matugen` if required
  - required writable DMS paths under sandboxing
- prefer an explicit, readable integration mechanism over unit-local PATH hacks

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- runtime validation on `predator`

Diff expectation:
- changes isolated to the custom wallpaper integration

Commit target:
- `fix(dms): repair custom wallpaper integration`

### Phase 4: Final runtime verification

Targets:
- live `predator`

Changes:
- verify clean login from a fresh boot or fresh graphical session

Validation:
- `systemctl --user --failed --no-pager`
- `systemctl --user status dms.service --no-pager`
- `systemctl --user status dms-awww.service --no-pager`
- `journalctl --user -b --no-pager | rg "dms|awww|qs|matugen"`

Diff expectation:
- no missing-binary failures
- no write-denied failures for DMS wallpaper integration

Commit target:
- `docs: record dms startup verification`

## Risks

- moving DMS ownership from NixOS to HM changes real runtime semantics and
  should be isolated from all other experiments
- `dms-awww` may still need a custom wrapper or runtime input strategy even
  after official DMS is fixed
- mixing DMS and `@persist` work again would make failures ambiguous

## Definition of Done

- `dms` follows the upstream HM ownership model
- `dms-awww` stays clearly separate as a custom integration
- `predator` starts DMS automatically again
- the branch is safe to resume `@persist` work afterward
