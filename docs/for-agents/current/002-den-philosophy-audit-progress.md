# Den Philosophy Audit Progress

## Status

Completed

## Related Plan

- [002-dms-home-manager-option-fix.md](/home/higorprado/nixos/docs/for-agents/plans/002-dms-home-manager-option-fix.md)
- [003-den-philosophy-alignment-refactors.md](/home/higorprado/nixos/docs/for-agents/plans/003-den-philosophy-alignment-refactors.md)

## Baseline

- Pulled `~/git/den` and reviewed the delta from `edaa0b0` to `4bdcb63`.
- The only upstream `den` commit in that range is `4bdcb63` from March 13, 2026: `feat(batteries): Opt-in den._.bidirectional (#272)`.
- Reviewed current den docs and CI tests, prioritizing code/tests over stale prose where they diverged.
- Scanned tracked `.nix` files in the repo for:
  - `den._.bidirectional`
  - `{ host, user }` parametric includes
  - `take.exactly` / `take.atLeast`
  - `home-manager.sharedModules`

## Slices

### Slice 1

- Read den implementation/docs/tests to extract the post-March-13 philosophy.
- Validation run:
  - doc and test inspection only
- Diff result:
  - no repo changes
- Commit:
  - none

Findings:
- Den's philosophy is now stricter about context width:
  - the context shape is the condition
  - host-to-user OS reentry is explicit, not implicit
  - `den._.bidirectional` is an opt-in escape hatch, not the default model
- Host-owned `homeManager` config is still first-class and continues to fan out to all HM users.
- The narrowest correct shape is the intended shape:
  - host-only concerns: `{ host }` or owned host config
  - generic HM concerns: owned `homeManager`
  - host-aware HM concerns: `{ host }`
  - user-specific logic: `{ host, user }` only when user data is actually needed

### Slice 2

- Checked the DMS fix against the new philosophy after the successful build/gate run.
- Validation run:
  - `nix flake metadata`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Diff result:
  - DMS is now aligned with current den usage
- Commit:
  - none

Findings:
- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix) is now correctly shaped:
  - host-only NixOS concern for `home-manager.sharedModules` and greeter wiring
  - owned `homeManager` config for generic DMS HM settings
- No tracked use of `den._.bidirectional` was found in the repo, which is good; nothing is trying to globally restore the old implicit pipeline.

### Slice 3

- Audited repo candidates for remaining context-width issues.
- Validation run:
  - static code audit only
- Diff result:
  - new report/plan docs only
- Commit:
  - none

Findings:
- High-priority architectural follow-up:
  - [modules/features/dev/llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix)
  - It currently mixes host-wide `nixos.environment.systemPackages` and HM packages inside `den.lib.parametric.exactly` with `{ host, user }`.
  - This is the same structural smell DMS had, but masked:
    - `predator` has `llmAgents.systemPackages = [ ]`
    - `aurelius` has non-empty `llmAgents.systemPackages`
  - Host-wide NixOS package wiring should not be coupled to HM user fan-out.
- Medium-priority alignment cleanups:
  - [modules/features/desktop/gui-apps.nix](/home/higorprado/nixos/modules/features/desktop/gui-apps.nix)
  - [modules/features/desktop/dms-wallpaper.nix](/home/higorprado/nixos/modules/features/desktop/dms-wallpaper.nix)
  - [modules/features/desktop/theme-zen.nix](/home/higorprado/nixos/modules/features/desktop/theme-zen.nix)
  - [modules/features/desktop/music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
  - These are HM-only host aspects using `{ host, user }` while `user` is unused. They should be narrowed to `{ host }`.
- Low-priority cleanup:
  - [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)
  - Its HM block does not use `host` or `user`, so it can be expressed as owned `homeManager` config while keeping the host-only `home-manager.sharedModules` include.
- Confirmed aligned patterns:
  - [modules/features/core/user-context.nix](/home/higorprado/nixos/modules/features/core/user-context.nix)
  - [modules/features/core/nix-settings.nix](/home/higorprado/nixos/modules/features/core/nix-settings.nix)
  - [modules/features/desktop/niri.nix](/home/higorprado/nixos/modules/features/desktop/niri.nix)
  - these already use host-only context where the concern is genuinely host-owned

## Final State

- The repo now has a validated DMS fix that matches den's current philosophy.
- The remaining repo-wide work is mostly context narrowing, with one real architectural follow-up in `llm-agents.nix`.
- A comprehensive execution plan for that follow-up work exists at [003-den-philosophy-alignment-refactors.md](/home/higorprado/nixos/docs/for-agents/plans/003-den-philosophy-alignment-refactors.md).
