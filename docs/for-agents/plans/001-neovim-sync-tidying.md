# Neovim Sync Tidying

## Status

Paused pending behavior decisions

## Goal

Tidy the tracked Neovim sync setup so the repo keeps only configuration and Nix wiring that is still actively used, while preserving the current `config/apps/nvim -> ~/.config/nvim` sync model and avoiding behavior regressions in the existing editor workflow.

## Scope

In scope:
- audit [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
- audit the synced Neovim tree under [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim)
- identify dead tracked files, template remnants, disabled integrations, and duplicated config
- remove or simplify confirmed dead code in small slices
- validate each meaningful slice with Nix and targeted headless Neovim checks

Out of scope:
- changing away from the current `rsync`-based sync model
- redesigning the Neovim plugin stack from scratch
- broad stylistic refactors in live Neovim Lua files unless they are required for cleanup
- changing unrelated editor tooling outside the Neovim feature

## Current State

- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) enables `programs.neovim` and syncs [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim) into `$HOME/.config/nvim` via `home.activation.syncNvimConfig`.
- The sync hook uses `rsync -a --delete`, so tracked files present under [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim) are authoritative for the runtime tree.
- The synced tree is a LazyVim-style layout with [config/apps/nvim/init.lua](/home/higorprado/nixos/config/apps/nvim/init.lua), [config/apps/nvim/lua/config/lazy.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/lazy.lua), and plugin overrides under [config/apps/nvim/lua/plugins](/home/higorprado/nixos/config/apps/nvim/lua/plugins).
- Confirmed dead/template remnants, stale lockfile entries, duplicated Treesitter pinning, and several redundant Lua overrides have already been removed in validated slices.
- The Nix feature still owns a Neovim runtime cleanup service/timer and a curated `home.packages` tool list; the clearly dead package leftovers were already pruned.
- The worktree is already dirty outside this task, including [config/apps/nvim/lua/plugins/core.lua](/home/higorprado/nixos/config/apps/nvim/lua/plugins/core.lua) and [flake.lock](/home/higorprado/nixos/flake.lock), so cleanup must avoid reverting unrelated user changes.
- Remaining candidates are no longer obvious dead code; they are behavior choices around completion, LSP, DAP, language extras, and profiling ergonomics.

## Desired End State

- Every tracked file under [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim) has a clear purpose in the live Neovim setup.
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) contains only live Neovim support logic, packages, and runtime maintenance that are still justified.
- Obvious template remnants and disabled or duplicate config are removed.
- The sync behavior still produces a working `~/.config/nvim` tree and does not regress the current editor workflow.
- Validation artifacts show only intentional changes.
- Any remaining tracked Neovim code is either kept by explicit behavior choice or removed in a follow-up plan.

## Phases

### Phase 0: Baseline

Targets:
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
- [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim)

Changes:
- no code changes
- capture baseline inventory of synced files, plugin specs, and Nix-owned Neovim packages
- classify candidate cleanup targets as `confirmed-dead`, `possibly-live`, or `needs-runtime-proof`
- record current dirty-worktree constraints in the progress log

Validation:
- `git status --short`
- `nix flake metadata path:$PWD`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- targeted headless Neovim probes for plugin/config loading where useful

Diff expectation:
- no tracked code changes

Commit target:
- none

### Phase 1: Remove Zero-Risk Template Remnants

Targets:
- [config/apps/nvim/lua/config/autocmds.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/autocmds.lua)
- [config/apps/nvim/lua/config/keymaps.lua](/home/higorprado/nixos/config/apps/nvim/lua/config/keymaps.lua)
- possibly [config/apps/nvim/README.md](/home/higorprado/nixos/config/apps/nvim/README.md)
- possibly [config/apps/nvim/LICENSE](/home/higorprado/nixos/config/apps/nvim/LICENSE)

Changes:
- remove files that are confirmed to be starter-template leftovers with no runtime effect
- keep any non-runtime docs only if they still add repo value

Validation:
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- inspect evaluated `xdg.configFile."nvim/init.lua".source` and resulting synced tree shape if needed
- headless `nvim` startup smoke for config load success

Diff expectation:
- only file deletions or doc-only removals in [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim)
- no Nix behavior changes beyond synced tree contents

Commit target:
- `chore(neovim): remove unused template files`

### Phase 2: Simplify Live Lua Config

Targets:
- [config/apps/nvim/lua/plugins](/home/higorprado/nixos/config/apps/nvim/lua/plugins)
- [config/apps/nvim/lua/config](/home/higorprado/nixos/config/apps/nvim/lua/config)

Changes:
- remove confirmed dead plugin overrides
- collapse duplicated or defensive fallback logic only when runtime proof shows it is unnecessary
- keep LazyVim inheritance assumptions explicit and avoid removing config that is only live via conventions or optional plugin hooks without proof

Validation:
- headless Neovim startup
- targeted plugin inspection commands for affected plugins
- compare `lazy-lock.json` and runtime references after each slice

Diff expectation:
- small Lua diffs with no change to the overall LazyVim import model

Commit target:
- `refactor(neovim): remove dead plugin config`

### Phase 3: Prune Nix-Side Neovim Wiring

Targets:
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)

Changes:
- remove or simplify unused packages in `home.packages` when they are no longer referenced by live Neovim behavior
- review whether the cleanup timer/service is still justified and scoped correctly
- keep the `rsync` activation model unless a cleanup change proves it is itself dead code, which is currently a non-goal

Validation:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix store diff-closures <baseline> <candidate>` if evaluated Nix behavior changes materially

Diff expectation:
- package-list or service/timer reductions only where supported by the audit

Commit target:
- `refactor(neovim): prune unused nix wiring`

### Phase 4: Final Validation and Documentation Closeout

Targets:
- touched Neovim files
- plan and progress docs

Changes:
- no functional changes unless validation exposes a cleanup regression
- update the progress log with actual slices, validation, and any residual risks

Validation:
- `./scripts/check-repo-public-safety.sh`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- only intended Neovim cleanup changes remain

Commit target:
- none if earlier slices were committed separately

## Risks

- LazyVim conventions can make files look unused when they are loaded implicitly.
- Optional plugin hooks in [config/apps/nvim/lua/plugins](/home/higorprado/nixos/config/apps/nvim/lua/plugins) may be intentionally inert until a tool is present in PATH.
- Removing Nix packages too aggressively can break editor features that are only exercised in specific project types.
- The current worktree is dirty, so cleanup must avoid conflating unrelated user changes with this task.

## Definition of Done

- a documented audit exists for the tracked Neovim sync setup
- confirmed dead files or config have been removed in small validated slices
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix) and [config/apps/nvim](/home/higorprado/nixos/config/apps/nvim) no longer carry confirmed dead code from earlier setup experiments
- required Nix validation and repo safety checks pass after the cleanup
- the active progress log records the slices, validations, and any remaining follow-up work
- if behavior-driven follow-up remains, the plan status makes that explicit instead of implying more dead-code cleanup is still underway
