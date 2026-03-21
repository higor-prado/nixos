# Structural Dendritic Alignment Progress

Related plan:
- [037-structural-dendritic-alignment.md](../plans/037-structural-dendritic-alignment.md)

## Baseline

- `modules/options/configurations-nixos.nix` still exported `flake.dendritic`.
- `modules/options/inventory.nix` contained only `options.username`.
- `modules/users/higorprado.nix` still hardcoded `userName = "higorprado"`.
- `modules/desktops/dms-on-niri.nix` and `modules/desktops/niri-standalone.nix`
  still used indirect composition via nested `imports`.
- Parallel host metadata still existed outside the runtime.

## Phase 0 Audit

Commands run:
- `rg -n "\\bflake\\.dendritic\\b|\\bdendritic\\b" . --glob '!docs/for-agents/archive/**' --glob '!flake.lock'`
- `rg -n "\\busername\\b|userName = \\\"higorprado\\\"" modules docs scripts tests`
- `rg -n "host-descriptors" . --glob '!docs/for-agents/archive/**'`
- `sed -n '1,220p' modules/options/configurations-nixos.nix`
- `sed -n '1,220p' modules/options/inventory.nix`
- `sed -n '1,260p' modules/users/higorprado.nix`
- `sed -n '1,240p' modules/desktops/dms-on-niri.nix`
- `sed -n '1,240p' modules/desktops/niri-standalone.nix`
- `sed -n '1,260p' scripts/check-extension-contracts.sh`

Findings:
- `flake.dendritic` has no active consumer in runtime code.
- `inventory.nix` was no longer inventory; it had become just the repo-wide
  `username` fact and needed to move to a more honest owner.
- The tracked username still has duplicate ownership between
  `modules/options/inventory.nix` and `modules/users/higorprado.nix`.
- The desktop composition modules are more indirect than necessary.
- Parallel host metadata still had script consumers, so it could not be removed
  blindly.

## Phase 1: Dead Flake Alias Removed

Changes:
- Deleted the dead `flake.dendritic` compatibility alias from
  `modules/options/configurations-nixos.nix`, later moved to `modules/nixos.nix`.

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

## Phase 2: Username Fact Aligned With The Reference

Changes:
- Replaced `modules/options/inventory.nix` with a dedicated owner for the
  `username` fact.
- Made `flake.nix` import that owner explicitly and exclude it from the
  recursive `import-tree` import, so the `username` fact is deterministic and
  no longer depends on tree traversal order.
- Updated `modules/users/higorprado.nix` to consume `config.username` instead
  of hardcoding `userName = "higorprado"`.
- Updated live architecture/ownership docs and the option-boundary gate to
  treat the tracked user owner as the place that owns that fact.

Validation:
- `nix eval .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.username`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Notes:
- Simply renaming `inventory.nix` was not enough. In this repo, the tracked
  `username` fact must be imported deterministically instead of depending on
  `import-tree` traversal order.

## Phase 3: Desktop Composition Modules Simplified

Changes:
- Simplified `modules/desktops/dms-on-niri.nix` and
  `modules/desktops/niri-standalone.nix` so they now assign their lower-level
  composition values directly instead of using indirect nested `imports`.
- Updated the human workflow doc to teach the direct form and local
  `inherit (config.flake.modules)` aliases.

## Phase 4: Top-Level Runtime Surfaces Moved To The Reference Layout

Changes:
- Moved `modules/options/configurations-nixos.nix` to `modules/nixos.nix`.
- Moved `modules/options/flake-parts-modules.nix` to `modules/flake-parts.nix`.
- Updated docs and the option-boundary gate so the runtime surface now matches
  the root-level layout used by the `dendritic` example more closely.

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh all`

## Phase 5: Parallel Host Metadata Removed

Changes:
- Removed the script-only parallel host metadata layer.
- Updated extension/onboarding tooling to derive host facts from the real repo
  structure.
- Removed the dedicated onboarding descriptor check and its fixture test.
