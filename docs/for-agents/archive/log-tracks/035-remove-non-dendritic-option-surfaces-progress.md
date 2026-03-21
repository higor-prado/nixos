# Remove Non-Dendritic Option Surfaces Progress

## Status

In progress

## Related Plan

- [035-remove-non-dendritic-option-surfaces.md](../plans/035-remove-non-dendritic-option-surfaces.md)

## Baseline

- The dendritic reference in `~/git/dendritic` exposes:
  - `options.username`
  - `options.configurations.nixos.*.module`
- The local repo still exposes extra local surfaces under `modules/options/`:
  - `repo.hosts.*`
  - `custom.host.role`
  - `custom.user.name`
- `repo-runtime-contracts.nix` still mixes option declarations with shared HM
  wiring.
- `repo.hosts.<name>.name` appears to be dead schema.

## Slices

### Slice 1

- Audited all active consumers of:
  - `repo.hosts.*`
  - `custom.host.role`
  - `custom.user.name`
  - `username`
- Confirmed that:
  - `repo.hosts.<name>.name` has no tracked runtime consumer
  - `repo-runtime-contracts.nix` is still a mixed-purpose file
  - `custom.host.role` is script-facing, not a runtime feature toggle
  - `custom.user.name` is still a bridge layered on top of `username`

Validation:
- `rg -n 'repo\\.hosts\\.|custom\\.host\\.role|custom\\.user\\.name|\\busername\\b' modules scripts tests docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans`
- `rg -n '^\\s*options\\.' modules/options modules/features`

Diff result:
- none

Commit:
- none

## Final State

- phase 0 audit opened
### Slice 2

- Removed dead inventory schema:
  - `repo.hosts.<name>.name`
- Removed the mixed-purpose Catppuccin HM wiring from
  `modules/options/repo-runtime-contracts.nix`
- Moved that shared HM wiring into the owner that already owns HM framework
  settings:
  - `modules/features/core/home-manager-settings.nix`
- Tightened docs so `repo-runtime-contracts.nix` stops being described as a bag
  of generic contracts plus unrelated wiring.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- less dead schema
- less mixed-purpose code in `modules/options/`

Commit:
- none

## Final State

- phase 0 completed
- one dead schema field is gone
- one piece of clearly misplaced wiring is out of the options layer
- next slice should attack whether `custom.user.name` and `custom.host.role`
  need to exist as declared option surfaces at all

### Slice 3

- Removed `repo.hosts.*` from the runtime surface entirely.
- Kept only the repo-wide `username` fact in `modules/options/inventory.nix`.
- Simplified host composition to use local host payload directly instead of a
  top-level host inventory layer.
- Updated generators, fixtures, docs, and script checks to stop depending on
  `repo.hosts.*` and `trackedUsers`.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-config-contracts.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- no runtime host inventory remains
- top-level options now look much closer to the dendritic reference

Commit:
- none

### Slice 4

- Removed the `custom.user.name` bridge from tracked runtime code.
- Lower-level host-aware modules now follow the dendritic reference pattern:
  they capture top-level `config` from the owner and read `config.username`
  there, instead of inventing a second selected-user surface inside NixOS.
- Updated validation scripts to read the concrete Home Manager user from
  `home-manager.users` state instead of reintroducing a runtime bridge.
- Updated tracked docs, skeletons, and examples so they no longer teach
  `custom.user.name`.
- Kept private overrides explicit: private host files now use the concrete local
  username directly instead of depending on tracked runtime surfaces.

Validation:
- `rg -n "custom\\.user\\.name" modules scripts tests docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans README.md AGENTS.md --glob '!docs/for-agents/archive/**'`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-config-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- no live `custom.user.name` remains outside archive/history
- no selected-user bridge remains in the tracked runtime

Commit:
- none

### Slice 5

- Reduced the remaining option surface to one honest purpose:
  `modules/options/host-role.nix`
- Renamed the old `repo-runtime-contracts` owner to `host-role`.
- Removed the default value from `custom.host.role` so missing host role now
  fails early instead of silently defaulting to `desktop`.
- Updated host imports, generator templates, fixtures, and living docs to use
  `nixos.host-role`.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-config-contracts.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `./scripts/run-validation-gates.sh all`

Diff result:
- no generic or mixed-purpose option bag remains
- `modules/options/` is down to:
  - `configurations-nixos.nix`
  - `inventory.nix`
  - `host-role.nix`
  - `flake-parts-modules.nix`

Commit:
- none

### Slice 6

- Removed `custom.host.role` from the runtime completely.
- Deleted `modules/options/host-role.nix`.
- Removed host-role imports from concrete hosts, templates, and fixtures.
- Removed `custom.host.role` assignments from tracked hardware defaults and
  hardware skeletons.
- Simplified scripts so they stop reading or synthesizing a runtime role field:
  - `run-validation-gates.sh`
  - `check-config-contracts.sh`
  - `check-runtime-smoke.sh`
  - `check-extension-simulations.sh`
  - `check-desktop-composition-matrix.sh`
  - extension-contract helper libs
- Kept only the guardrail that forbids reintroducing `custom.host.role` inside
  feature code.
- Updated living docs to stop describing host role as a runtime surface.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-config-contracts.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `./scripts/run-validation-gates.sh all`
- `rg -n "custom\\.host\\.role|host-role|repo-runtime-contracts" docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans README.md AGENTS.md modules templates tests scripts --glob '!docs/for-agents/archive/**'`
- `rg -n "mkOption" modules/options modules/features modules/desktops`

Diff result:
- no script-only role selector remains in the runtime
- `modules/options/` is down to:
  - `configurations-nixos.nix`
  - `inventory.nix`
  - `flake-parts-modules.nix`
- live `mkOption` count is now down to the structural/user-fact surfaces plus
  the narrow feature option in `niri.nix`

Commit:
- none
