# Dev Module Reorganization Progress

## Status

Completed

## Related Plan

- [101-dev-module-reorganization.md](/home/higorprado/nixos/docs/for-agents/plans/101-dev-module-reorganization.md)

## Baseline

- Validation gates: PASS (structure)
- nix eval predator stateVersion: "25.11"
- Uncommitted changes: dev-tools.nix (+12 linters), packages-toolchains.nix (+bun)
- Strategy: stash pending → work from clean HEAD → absorb additions into new structure

## Slices

### Phase 1 — Create linters.nix

- Created `modules/features/dev/linters.nix` publishing `homeManager.linters`
- All 13 linters: nixfmt + 12 from staged additions
- `nix eval` — module auto-imported, valid
- Commit: `feat(dev): add linters module for language linters and formatters`

### Phase 2 — Relocate shell tools to core-user-packages

- Added `bat`, `eza` (+ `programs.bat`, `programs.eza`), `jq`, `fd`, `tree`, `sd` to `shell/core-user-packages.nix`
- Removed them + duplicate `gh` from `dev/dev-tools.nix`
- `nix eval` predator HM: all packages reachable, `gh` single-sourced from `git-gh.nix`
- Commit: `refactor(dev): relocate shell tools from dev-tools to core-user-packages`

### Phase 3 — Move uv to toolchains, add bun

- Added `uv` + `bun` to `packages-toolchains.nix`
- Removed `uv` from `dev-tools.nix`
- `dev-tools.nix` now only has `nixfmt` (redundant with linters.nix)
- `nix eval` predator + aurelius: both pass
- Commit: `refactor(dev): move uv to toolchains, add bun`

### Phase 4 — Rename files for flat naming

- 7 `git mv` operations + published module name updates:
  - `dev-devenv.nix` → `devenv.nix` (`homeManager.devenv`)
  - `editor-emacs.nix` → `editors-emacs.nix` (`homeManager.editors-emacs`)
  - `editor-neovim.nix` → `editors-neovim.nix` (`nixos.editors-neovim` + `homeManager.editors-neovim`)
  - `editor-vscode.nix` → `editors-vscode.nix` (`homeManager.editors-vscode`)
  - `editor-zed.nix` → `editors-zed.nix` (`homeManager.editors-zed`)
  - `packages-toolchains.nix` → `toolchains.nix` (`homeManager.toolchains`)
  - `packages-docs-tools.nix` → `docs-tools.nix` (`homeManager.docs-tools`)
- `llm-agents.nix` kept as-is (already flat name)
- Commit: `refactor(dev): adopt flat naming convention for dev modules`

### Phase 5 — Delete dev-tools.nix

- `git rm modules/features/dev/dev-tools.nix`
- Commit: `refactor(dev): remove dev-tools grab-bag, superseded by linters module`

### Phase 6 — Update host import lists

- Updated `nixos.editor-neovim` → `nixos.editors-neovim` in all 3 hosts
- Updated hmDev lists:
  - predator: 9 imports (devenv, editors-\*, llm-agents, toolchains, linters, docs-tools)
  - aurelius: 4 imports (devenv, editors-neovim, linters, toolchains)
  - cerebelo: 2 imports (editors-neovim, linters)
- `nix eval` all 3 hosts: PASS
- Commit: `refactor(hosts): update hmDev imports for dev module reorg`

### Phase 7 — Docs + final validation

- Updated `docs/for-agents/001-repo-map.md` and `docs/for-agents/003-module-ownership.md`
- `./scripts/run-validation-gates.sh structure`: ALL PASS
- `./scripts/check-repo-public-safety.sh`: PASS
- `nix build --no-link` predator (NixOS + HM): PASS
- All 13 linters confirmed present in predator HM derivation
- `grep -r` stale names in modules/: CLEAN
- Commit: `docs: update repo map and ownership docs for dev module reorg`

## Final State

### dev/ directory (9 files)

```
devenv.nix           → homeManager.devenv
editors-emacs.nix    → homeManager.editors-emacs
editors-neovim.nix   → nixos.editors-neovim + homeManager.editors-neovim
editors-vscode.nix   → homeManager.editors-vscode
editors-zed.nix      → homeManager.editors-zed
llm-agents.nix       → homeManager.llm-agents
toolchains.nix       → homeManager.toolchains
linters.nix          → homeManager.linters
docs-tools.nix       → homeManager.docs-tools
```

### Package relocation map

| Package(s)          | Old location  | New location                 |
| ------------------- | ------------- | ---------------------------- |
| bat, eza            | dev-tools.nix | shell/core-user-packages.nix |
| jq, fd, tree, sd    | dev-tools.nix | shell/core-user-packages.nix |
| gh (duplicate)      | dev-tools.nix | Removed                      |
| uv                  | dev-tools.nix | toolchains.nix               |
| bun (staged)        | —             | toolchains.nix               |
| 12 linters (staged) | —             | linters.nix                  |
| nixfmt              | dev-tools.nix | linters.nix                  |
| dev-tools.nix       | —             | Deleted                      |

### Decision tree delivered

Clear rules for any new development package — see plan §3.

### What remains open

- The stash `pending: linters + bun additions for dev reorg` can be dropped
  (contents absorbed into new structure)
- `flake.lock` has unrelated pending modifications (not part of this task)
