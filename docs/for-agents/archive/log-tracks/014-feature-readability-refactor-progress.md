# Feature Readability Refactor Progress

Date: 2026-03-10
Status: completed

Plan:
- `docs/for-agents/plans/012-feature-readability-refactor-plan.md`

## Baseline

Current feature tree characteristics:
- flat `modules/features/` layout
- strong latent naming families (`ai-*`, `editor-*`, `media-*`, `networking*`, `packages-*`, `tui-*`)
- a few misleadingly broad file names
- one confirmed empty feature candidate: `desktop/media-apps.nix`
- one ownership-based split candidate: `theme.nix`

## Phase Checklist

- [x] Phase 0: baseline capture and naming freeze
- [x] Phase 1: category folder move
- [x] Phase 2: file rename pass
- [x] Phase 3: remove obvious dead weight
- [x] Phase 4: optional thin-wrapper merge pass
- [x] Phase 5: optional ownership-based split pass

## Notes

- Path-only and filename-only phases should keep closure diffs empty.
- Aspect renames are intentionally deferred unless a current aspect name is
  itself misleading.
- Docs and validation contracts are part of the refactor surface, not cleanup
  afterthoughts.

## Phase 0 Snapshot

- `./scripts/run-validation-gates.sh structure` -> pass
- `/tmp/feature-layout-before-system` captured as baseline predator system closure
- `/tmp/feature-layout-before-hm` captured as baseline predator HM closure
- identified relative-import updates required by the category move:
  - `shell/tmux.nix`
  - `shell/htop-config.nix`
  - `desktop/niri.nix`
  - `desktop/dms.nix`
  - `desktop/dms-wallpaper.nix`
  - `desktop/music-client.nix`
  - `dev/editor-neovim.nix`

## Phase 1 Working Notes

- feature files have been regrouped under:
  - `core/`
  - `system/`
  - `shell/`
  - `desktop/`
  - `dev/`
  - `ai/`
- aspect names remain unchanged in this phase
- living docs are being updated to describe the categorized tree instead of the old flat layout

## Phase 1 Result

Outcome:
- `modules/features/` is now organized under:
  - `core/`
  - `system/`
  - `shell/`
  - `desktop/`
  - `dev/`
  - `ai/`
- aspect names stayed stable
- living docs now describe the categorized tree
- relative imports in moved modules were adjusted to preserve behavior

## Phase 2 Working Notes

- high-confidence filename normalization is in progress
- aspect names still remain unchanged
- the main docs surface affected is the repo map and the readability plan/tracker

## Phase 2 Result

Renames completed:
- `shell/core-user-packages.nix` -> `shell/cli-base.nix`
- `shell/monitoring-tools.nix` -> `shell/htop-config.nix`
- `shell/terminal.nix` -> `shell/default-terminal.nix`
- `shell/terminal-tmux.nix` -> `shell/tmux.nix`
- `shell/terminals.nix` -> `shell/terminal-emulators.nix`
- `desktop/desktop-base.nix` -> `desktop/xdg-user-dirs.nix`
- `desktop/desktop-apps.nix` -> `desktop/gui-apps.nix`
- `desktop/desktop-viewers.nix` -> `desktop/viewers.nix`
- `system/packages-system-tools.nix` -> `system/filesystem-tools.nix`
- `system/packages-server-tools.nix` -> `system/server-cli-tools.nix`
- `dev/packages-toolchains.nix` -> `dev/toolchains.nix`
- `dev/packages-docs-tools.nix` -> `dev/docs-tools.nix`

Validation:
- `./scripts/check-docs-drift.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase2-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase2-hm` -> pass
- `nix store diff-closures /tmp/feature-layout-phase1-system /tmp/feature-layout-phase2-system` -> empty
- `nix store diff-closures /tmp/feature-layout-phase1-hm /tmp/feature-layout-phase2-hm` -> empty

## Phase 3 Working Notes

- removed the empty `media-apps` aspect file
- removed the matching no-op include from `predator`
- expected behavior change: none

## Phase 3 Result

Validation:
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase3-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase3-hm` -> pass
- `nix store diff-closures /tmp/feature-layout-phase2-system /tmp/feature-layout-phase3-system` -> empty
- `nix store diff-closures /tmp/feature-layout-phase2-hm /tmp/feature-layout-phase3-hm` -> empty

## Phase 4 Working Notes

- merged thin desktop media package wrappers into `desktop/media-tools.nix`
- merged thin TUI wrappers into `shell/tui-tools.nix`
- `predator` now includes the two bundles instead of seven tiny wrapper aspects

## Phase 4 Result

Validation:
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase4-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase4-hm` -> pass
- `nix store diff-closures /tmp/feature-layout-phase3-system /tmp/feature-layout-phase4-system` -> empty
- `nix store diff-closures /tmp/feature-layout-phase3-hm /tmp/feature-layout-phase4-hm` -> empty

## Phase 5 Working Notes

- `desktop/theme.nix` is now the public composition aspect
- base Catppuccin/GTK/cursor ownership moved to `desktop/theme-base.nix`
- Zen-specific sync logic moved to `desktop/theme-zen.nix`

## Phase 5 Result

Validation:
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase5-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase5-hm` -> pass
- `nix store diff-closures /tmp/feature-layout-phase4-system /tmp/feature-layout-phase5-system` -> empty
- `nix store diff-closures /tmp/feature-layout-phase4-hm /tmp/feature-layout-phase5-hm` -> empty

## Closeout

Completed outcomes:
- feature modules grouped into six categories
- high-confidence filename normalization completed
- the empty `media-apps` feature was removed
- thin media/TUI wrappers were consolidated into two bundles
- `theme` was split by ownership while preserving the public include surface

Remaining note:
- the repo still intentionally keeps aspect names stable even when filenames
  improved; that was a deliberate scope choice in this refactor
