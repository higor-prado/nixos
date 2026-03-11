# DMS Startup Research Plan

## Goal

Understand the correct upstream-aligned fix for `predator` startup without
mixing `DankMaterialShell` (`dms`) with the custom `dms-awww` wallpaper
integration, and without applying more runtime hacks before the ownership model
is clear.

## Scope

In scope:
- upstream DMS NixOS/Home Manager modules
- current tracked `dms` and `dms-wallpaper` aspects
- documenting the correct remediation direction

Out of scope:
- changing tracked code now
- persisting Docker/Podman work
- activating anything on `predator`

## Current State

- `dms` and `dms-awww` are separate concerns.
- `dms` is an upstream package/module with official NixOS and Home Manager
  modules.
- `dms-awww` is a custom package written by the repo owner.
- Boot logs previously showed:
  - `dms.service`: `qs` not found in `$PATH`
  - `dms-awww.service`: `awww` not found in `$PATH`
  - later `dms-awww`: write failure under `~/.config/DankMaterialShell`
- An earlier attempt mixed the two concerns and was reverted.

## Research Findings

### Upstream DMS ownership split

- Upstream `distro/nix/nixos.nix` defines `systemd.user.services.dms` but also
  forces `path = [ ]`.
- Upstream `distro/nix/home.nix` is the cleaner user-facing path:
  - enables `programs.quickshell`
  - installs the DMS runtime packages into `home.packages`
  - defines `systemd.user.services.dms`
  - writes user config/state files

### Repo mismatch

- The repo currently owns `dms` from the NixOS side in
  `modules/features/desktop/dms.nix`.
- That likely explains the startup mismatch: the repo is bypassing the upstream
  HM ownership path for the user service.

### Separate custom integration

- `modules/features/desktop/dms-wallpaper.nix` is a custom HM-side integration
  for `dms-awww`.
- Its runtime issue should be solved independently of the official DMS module.

## Desired End State

- `dms` user runtime follows the upstream Home Manager ownership model.
- NixOS-side DMS config is limited to the parts that are truly system/greeter
  concerns.
- `dms-awww` remains a separate custom integration and is fixed on its own
  terms.

## Phases

### Phase 0: Research capture

Validation:
- confirm upstream DMS NixOS vs HM behavior
- confirm current repo split

### Phase 1: Migration plan only

Targets:
- `modules/features/desktop/dms.nix`
- `modules/features/desktop/dms-wallpaper.nix`

Changes:
- none yet
- write the intended ownership migration before editing code

Validation:
- `./scripts/check-docs-drift.sh`

## Risks

- Moving `dms` to HM ownership changes real startup wiring and should not be
  mixed with the pending disk experiment.
- `dms-awww` may still require a custom wrapper or runtime input strategy even
  after `dms` is fixed.

## Definition of Done

- the upstream-aligned direction is documented clearly
- failed/reverted attempts are preserved in factual tracking docs
- no code changes are made until the migration plan is explicit
