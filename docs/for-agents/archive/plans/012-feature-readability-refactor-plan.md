# Feature Readability Refactor Plan

Date: 2026-03-10
Status: planned

Execution log:
- `docs/for-agents/current/014-feature-readability-refactor-progress.md`

## Goal

Improve readability and maintainability of `modules/features/` by:

1. introducing a small number of clear feature categories,
2. moving feature files into category folders,
3. renaming misleading files where that improves navigation,
4. removing obviously useless files,
5. evaluating a narrow set of justified split/merge candidates.

This is a readability and ownership cleanup, not a den architecture rewrite.

## Source Review

Reviewed for this plan:
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/006-extensibility.md`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- the full `modules/features/` tree
- relevant validation scripts that might assume a flat feature tree

## Current Diagnosis

## 1. The feature tree is flat even though naming already encodes categories

Current file families already reveal latent categories:
- `ai-*`
- `editor-*`
- `media-*`
- `networking*`
- `packages-*`
- `tui-*`

This means the repo already wants categorical grouping, but the filesystem does
not help the reader.

## 2. Some file names are broader than the behavior they actually own

High-confidence examples:
- `modules/features/shell/htop-config.nix`
  only provisions `htop` config
- `modules/features/system/filesystem-tools.nix`
  currently only installs `btrfs-progs`
- `modules/features/desktop/xdg-user-dirs.nix`
  currently only owns `xdg.userDirs`
- `modules/features/shell/default-terminal.nix`
  only sets the default `TERMINAL`
- `modules/features/shell/terminal-emulators.nix`
  owns emulator configs, not "all terminal behavior"

## 3. A few micro-features are probably too fine-grained for current usage

Current tiny wrapper modules:
- `modules/features/media-pavucontrol.nix`
- `modules/features/media-vlc.nix`
- `modules/features/media-yt-dlp.nix`
- `modules/features/tui-lazydocker.nix`
- `modules/features/tui-lazygit.nix`
- `modules/features/tui-yazi.nix`
- `modules/features/tui-zellij.nix`

These are not automatically wrong. The readability question is whether the
inclusion granularity is still buying enough value to justify the file count.

## 4. At least one feature file currently adds no behavior

- `modules/features/media-apps.nix`
  is an empty aspect and is the clearest deletion candidate.

## 5. Some larger files should stay intact unless ownership actually splits

These files are large, but still mostly coherent by ownership:
- `modules/features/fish.nix`
- `modules/features/editor-neovim.nix`
- `modules/features/shell/terminal-emulators.nix`
- `modules/features/niri.nix`

This plan does **not** recommend splitting them just for LOC.

## 6. One large file has a real split candidate

- `modules/features/theme.nix`

It currently mixes:
- general Catppuccin/GTK/cursor theming,
- app-specific Zen Browser sync logic,
- a long imperative activation block.

That is a legitimate ownership-based split candidate, but it should be later
than the filesystem/name cleanup.

## Target Category Model

Use **six** top-level feature categories:

1. `modules/features/core/`
2. `modules/features/system/`
3. `modules/features/shell/`
4. `modules/features/desktop/`
5. `modules/features/dev/`
6. `modules/features/ai/`

This keeps the number of categories small while still matching the real shape
of the repo.

## Proposed Category Mapping

### `core/`

Purpose:
- framework/contract/base modules that are foundational to every host or to the
  den wiring model

Files:
- `home-manager-settings.nix`
- `host-contracts.nix`
- `nix-settings.nix`
- `system-base.nix`
- `user-context.nix`

### `system/`

Purpose:
- system services, connectivity, security, virtualization, host runtime
  facilities, and system-scoped package bundles

Files:
- `audio.nix`
- `backup-service.nix`
- `bluetooth.nix`
- `docker.nix`
- `keyboard.nix`
- `keyrs.nix`
- `maintenance.nix`
- `networking.nix`
- `networking-avahi.nix`
- `networking-resolved.nix`
- `server-cli-tools.nix`
- `filesystem-tools.nix`
- `podman.nix`
- `security.nix`
- `ssh.nix`
- `tailscale.nix`
- `upower.nix`

### `shell/`

Purpose:
- shell, CLI, terminal, TUI, and generic user command-line ergonomics

Files:
- `cli-base.nix`
- `fish.nix`
- `git-gh.nix`
- `htop-config.nix`
- `starship.nix`
- `default-terminal.nix`
- `tmux.nix`
- `terminal-emulators.nix`
- `tui-lazydocker.nix`
- `tui-lazygit.nix`
- `tui-yazi.nix`
- `tui-zellij.nix`
- `_starship-settings.nix`

### `desktop/`

Purpose:
- GUI/Wayland/session features, theming, desktop apps, media UX, and desktop
  package sets

Files:
- `gui-apps.nix`
- `xdg-user-dirs.nix`
- `viewers.nix`
- `dms-wallpaper.nix`
- `dms.nix`
- `fcitx5.nix`
- `gnome-keyring.nix`
- `media-apps.nix`
- `media-cava.nix`
- `media-pavucontrol.nix`
- `media-vlc.nix`
- `media-yt-dlp.nix`
- `music-client.nix`
- `nautilus.nix`
- `niri.nix`
- `packages-fonts.nix`
- `theme.nix`
- `wayland-tools.nix`
- `xwayland.nix`

### `dev/`

Purpose:
- development tooling, editors, templates, and dev package bundles

Files:
- `dev-devenv.nix`
- `dev-tools.nix`
- `editor-emacs.nix`
- `editor-neovim.nix`
- `editor-vscode.nix`
- `editor-zed.nix`
- `docs-tools.nix`
- `toolchains.nix`

### `ai/`

Purpose:
- AI/code-assistant features and related local tooling

Files:
- `ai-claude-code.nix`
- `ai-codex.nix`
- `ai-crush.nix`
- `ai-kilocode.nix`
- `ai-openclaw.nix`
- `ai-opencode.nix`

## Naming Policy

## Rule 1

First move files into categories **without renaming aspect names**.

Why:
- host includes use aspect names, not file paths
- path-only moves give the lowest-risk structural cleanup
- diff-based validation should stay empty for these phases

## Rule 2

Rename files before renaming aspects.

Why:
- file-path renames improve navigation immediately
- aspect renames are more invasive and require host changes
- many aspect names are good enough even when file names are not

## Rule 3

Only rename an aspect when the aspect name is itself misleading, not merely
because the file path changed.

## Recommended File Rename Candidates

High-confidence renames:
- `core-user-packages.nix` -> `shell/cli-base.nix`
- `monitoring-tools.nix` -> `shell/htop-config.nix`
- `terminal.nix` -> `shell/default-terminal.nix`
- `terminal-tmux.nix` -> `shell/tmux.nix`
- `terminals.nix` -> `shell/terminal-emulators.nix`
- `desktop-base.nix` -> `desktop/xdg-user-dirs.nix`
- `desktop-apps.nix` -> `desktop/gui-apps.nix`
- `desktop-viewers.nix` -> `desktop/viewers.nix`
- `packages-system-tools.nix` -> `system/filesystem-tools.nix`
- `packages-server-tools.nix` -> `system/server-cli-tools.nix`
- `packages-toolchains.nix` -> `dev/toolchains.nix`
- `packages-docs-tools.nix` -> `dev/docs-tools.nix`

Low-confidence rename candidates that may be unnecessary:
- `backup-service.nix`
- `home-manager-settings.nix`
- `music-client.nix`

These should only be renamed if the chosen new name is clearly better than the
current one.

## Split / Merge Recommendations

## High-confidence removals

1. Remove `modules/features/media-apps.nix`
   if it still remains behaviorless during execution.

## High-confidence keep-as-is

Do **not** split just for size:
- `fish.nix`
- `editor-neovim.nix`
- `terminals.nix`
- `niri.nix`
- `dms-wallpaper.nix`

## Medium-confidence merge candidates

1. Merge:
   - `media-pavucontrol.nix`
   - `media-vlc.nix`
   - `media-yt-dlp.nix`

   Candidate target:
   - `desktop/media-tools.nix`

   Rationale:
   - all are tiny HM-only package wrappers
   - they are currently co-included on `predator`
   - none currently owns meaningful custom options

   Caution:
   - do this only if no host-level subset selection is expected soon

2. Evaluate merging:
   - `tui-lazydocker.nix`
   - `tui-lazygit.nix`
   - `tui-yazi.nix`
   - `tui-zellij.nix`

   Candidate target:
   - `shell/tui-tools.nix`

   Rationale:
   - current file count is high relative to behavior size

   Caution:
   - this loses some inclusion granularity, so it should happen only if the
     repo is comfortable treating them as one ergonomic bundle

## Medium-confidence split candidate

1. Split `modules/features/theme.nix` into:
   - a general Catppuccin/theme owner
   - a Zen Browser sync owner

   Rationale:
   - the Zen-specific activation logic is the only clearly separate ownership
     domain in the file

   Caution:
   - keep the public host include surface simple
   - if split, consider retaining `theme` as a composition aspect that includes
     the narrower theme pieces

## Explicit Non-Goals

- Do not rename every aspect just because files moved
- Do not split large files only because of LOC
- Do not change host behavior during the category-path move phases
- Do not introduce a second migration framework just for path renames
- Do not touch `flake.lock` as part of this plan

## Tooling Impact

This refactor is expected to be mostly docs/tooling-sensitive, not runtime-sensitive.

Important observations:
- den auto-discovers recursively under `modules/`, so nested feature folders are
  compatible with the framework
- `scripts/check-option-declaration-boundary.sh` allows the `modules/features/`
  prefix, so subfolders under that root remain valid
- the main drift risk is docs and any tests/scripts that still assume a flat
  `modules/features/<name>.nix` layout

Known docs/contracts that will need updates:
- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-humans/02-structure.md`
- `docs/for-humans/workflows/102-add-feature.md`

## Execution Strategy

## Phase 0: Baseline and Naming Freeze

Capture:
- current feature inventory
- current host include inventory
- baseline `predator` system/HM closures

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-before-hm
```

## Phase 1: Category Folder Move Only

Move files into the six category folders, but keep existing filenames and aspect
names unchanged.

Goal:
- improve filesystem readability with minimal semantic risk

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
bash tests/scripts/new-host-skeleton-fixture-test.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase1-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase1-hm
nix store diff-closures /tmp/feature-layout-before-system /tmp/feature-layout-phase1-system
nix store diff-closures /tmp/feature-layout-before-hm /tmp/feature-layout-phase1-hm
```

Expected diff:
- empty

Commit target:
- `refactor: group feature modules by category`

## Phase 2: File Rename Pass

Rename only the high-confidence misleading file names.

Keep aspect names stable unless a rename is clearly necessary.

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase2-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase2-hm
nix store diff-closures /tmp/feature-layout-phase1-system /tmp/feature-layout-phase2-system
nix store diff-closures /tmp/feature-layout-phase1-hm /tmp/feature-layout-phase2-hm
```

Expected diff:
- empty

Commit target:
- `refactor: normalize feature file names`

## Phase 3: Remove Obvious Dead Weight

Primary candidate:
- delete `media-apps.nix` if it still has no behavior and no planned purpose

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase3-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase3-hm
nix store diff-closures /tmp/feature-layout-phase2-system /tmp/feature-layout-phase3-system
nix store diff-closures /tmp/feature-layout-phase2-hm /tmp/feature-layout-phase3-hm
```

Expected diff:
- empty, unless the file had hidden behavior added before execution

Commit target:
- `refactor: remove empty feature modules`

## Phase 4: Optional Thin-Wrapper Merge Pass

Evaluate and possibly merge:
- media wrappers into `media-tools`
- TUI wrappers into `tui-tools`

Rule:
- only merge if the resulting bundle still matches actual inclusion patterns

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase4-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase4-hm
nix store diff-closures /tmp/feature-layout-phase3-system /tmp/feature-layout-phase4-system
nix store diff-closures /tmp/feature-layout-phase3-hm /tmp/feature-layout-phase4-hm
```

Expected diff:
- empty

Commit target:
- `refactor: merge thin wrapper feature modules`

## Phase 5: Optional Ownership-Based Split Pass

Primary candidate:
- split `theme.nix` into narrower ownership units while preserving a simple
  include surface

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/feature-layout-phase5-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/feature-layout-phase5-hm
nix store diff-closures /tmp/feature-layout-phase4-system /tmp/feature-layout-phase5-system
nix store diff-closures /tmp/feature-layout-phase4-hm /tmp/feature-layout-phase5-hm
```

Expected diff:
- empty

Commit target:
- `refactor: split theme ownership by concern`

## Recommended Order

1. Phase 0 baseline
2. Phase 1 category-folder move
3. Phase 2 file rename pass
4. Phase 3 remove empty features
5. Phase 4 optional merge pass
6. Phase 5 optional split pass

This order gives the highest readability gain earliest while keeping the first
three phases diff-stable and low-risk.

## Success Criteria

- `modules/features/` is grouped into a small number of readable categories
- the repo no longer relies on a flat feature tree for discoverability
- clearly misleading filenames are gone
- empty/no-op feature files are removed
- merge/split work happens only where ownership or file-count benefits justify it
- docs and validation tooling describe the new layout correctly
- pure path/name cleanup phases produce empty closure diffs
