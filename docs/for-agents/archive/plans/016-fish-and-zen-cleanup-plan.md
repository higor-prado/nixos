# Fish And Zen Cleanup Plan

## Goal

Apply two small readability cleanups without turning them into architecture work:

1. simplify `modules/features/shell/fish.nix`
2. extract the inline Zen Browser activation shell body from
   `modules/features/desktop/theme-zen.nix` into tracked `config/`

This is intentionally a pragmatic cleanup plan, not a broad refactor.

## Scope

In scope:
- `modules/features/shell/fish.nix`
- `modules/features/desktop/theme-zen.nix`
- a new tracked Zen helper script under `config/`
- docs that describe config placement and feature ownership

Out of scope:
- changing fish ownership across NixOS vs Home Manager
- redesigning shell abbreviation precedence
- moving personal/private shell paths into a new option model
- changing Zen theme behavior
- changing host selection or den context architecture

## Current State

### Fish

`modules/features/shell/fish.nix` currently has:

- duplicated base abbreviations in both:
  - `nixos.programs.fish.shellAbbrs`
  - `homeManager.programs.fish.shellAbbrs`
- HM-only abbreviations mixed in the same attribute set
- inline personal `fish_add_path` entries for:
  - `~/.bun/bin`
  - `~/.opencode/bin`
  - `~/.npm-packages/bin`
  - `~/.config/emacs/bin`

Important nuance:
- duplication of identical abbreviations is ugly but not a correctness bug
- `fish_add_path` to a nonexistent directory is not fatal, but it is still noisy
  and obscures which paths are genuinely part of the tracked shell environment

### Zen

`modules/features/desktop/theme-zen.nix` contains a long inline activation shell
body that:

- locates the Zen profile via `profiles.ini`
- copies Catppuccin theme CSS/logo assets into the live profile
- ensures `toolkit.legacyUserProfileCustomizations.stylesheets` is enabled in
  `user.js`

The ownership is correct, but the placement is poor:
- shell logic is embedded inline in the Nix module
- it is harder to read and review than a tracked script under `config/`

## Desired End State

### Fish

Keep the same behavior, but make the file easier to read:

- define base abbreviations once in a local `let`
- merge them into:
  - NixOS fish abbreviations
  - HM fish abbreviations
- keep HM-only abbreviations in a separate local attrset
- do not add new options or shared libs for this

For shell paths:
- remove clearly obsolete tracked path entries if they are no longer needed
- especially reassess `~/.opencode/bin` now that `opencode` is installed from Nix
- for remaining mutable personal paths, prefer a tiny guarded form instead of
  bare unconditional `fish_add_path`

### Zen

Move the activation shell body into a tracked script under `config/`, for example:

- `config/apps/zen/sync-catppuccin-theme.sh`

The module should keep ownership of:
- theme parameters
- asset paths
- HM activation hook wiring

The script should own:
- profile discovery logic
- file copy logic
- `user.js` patch/append logic

## Refactor Strategy

### Phase 0: Baseline

Capture current behavior before edits.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/fish-zen-before-system`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/fish-zen-before-hm`

### Phase 1: Fish cleanup

Target file:
- `modules/features/shell/fish.nix`

Planned changes:
- introduce local `baseAbbrs`
- introduce local `hmOnlyAbbrs`
- keep host override merge only on the NixOS side where it already exists
- simplify shell path logic:
  - remove obviously obsolete tracked entries
  - guard remaining mutable paths with `test -d`

Non-goals for this phase:
- no new feature options
- no new helper library
- no separate private/public path model

Expected result:
- no semantic change to base fish aliases
- lower duplication
- clearer distinction between tracked shell environment and mutable personal paths

Validation:
- `./scripts/run-validation-gates.sh structure`
- `bash scripts/check-changed-files-quality.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/fish-zen-phase1-system`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/fish-zen-phase1-hm`
- `nix store diff-closures /tmp/fish-zen-before-system /tmp/fish-zen-phase1-system`
- `nix store diff-closures /tmp/fish-zen-before-hm /tmp/fish-zen-phase1-hm`

Diff expectation:
- empty, or only harmless text-generation changes in fish config with no package
  or service impact

Commit target:
- `refactor: simplify fish abbreviations and path setup`

### Phase 2: Zen script extraction

Target files:
- `modules/features/desktop/theme-zen.nix`
- `config/apps/zen/sync-catppuccin-theme.sh` (new)

Planned changes:
- move the inline activation shell body into a tracked shell script in `config/`
- keep dynamic values passed from Nix in a narrow way, for example via:
  - script arguments, or
  - a generated wrapper with exported env vars
- keep the HM activation hook in the module
- keep the activation ordering unchanged (`entryAfter [ "writeBoundary" ]`)

Preferred pattern:
- store the readable shell logic in `config/apps/zen/sync-catppuccin-theme.sh`
- let the module call it through a small `writeShellScript` wrapper that injects:
  - `themeDir`
  - `logoFile`
  - `coreutils`, `gawk`, `gnugrep`, `gnused`
  - `DRY_RUN_CMD`

Why this pattern:
- the script becomes readable and reviewable
- the Nix module still owns dependency injection and activation wiring
- no private runtime mutation is moved outside tracked config

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/fish-zen-phase2-system`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/fish-zen-phase2-hm`
- `nix store diff-closures /tmp/fish-zen-phase1-system /tmp/fish-zen-phase2-system`
- `nix store diff-closures /tmp/fish-zen-phase1-hm /tmp/fish-zen-phase2-hm`

Diff expectation:
- empty

Commit target:
- `refactor: extract zen theme sync script`

### Phase 3: Docs reconciliation

Update docs only where the cleanup changes live structure or guidance:

- `docs/for-agents/001-repo-map.md`
- any docs that enumerate `config/apps/*`
- any docs that describe fish as if the current duplication were intentional

Validation:
- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`

Commit target:
- `docs: record fish and zen cleanup`

## Risk Analysis

### Fish risk

Low, if behavior is preserved:
- abbreviations already exist in both surfaces
- this cleanup is mainly deduplication plus path hygiene

Main risk:
- accidentally removing a path that is still intentionally needed

Mitigation:
- remove only paths that are clearly obsolete
- otherwise keep them, but guard them with `test -d`

### Zen risk

Low to medium:
- behavior should stay identical
- but the activation shell body is non-trivial

Main risks:
- quoting mistakes when moving from inline shell to tracked script
- losing access to HM activation variables like `DRY_RUN_CMD`

Mitigation:
- keep runtime values injected by a small Nix wrapper
- preserve activation order
- validate with HM closure diff after extraction

## Definition of Done

- fish base abbreviations are defined once
- HM-only abbreviations remain in HM only
- clearly obsolete mutable path entries are removed or remaining ones are guarded
- Zen activation shell logic lives under `config/apps/zen/`
- `theme-zen.nix` is shorter and more declarative
- docs reflect the new config file location
- all validations pass

## Notes For The Executing Agent

- Do not overengineer fish.
- Do not create a generic shell path framework.
- Do not create a shared script helper for Zen unless the existing extraction
  cannot be done cleanly with one local wrapper.
- Preserve behavior first; improve readability second.
