# Shell Module Cleanup Progress

## Status

Completed

## Related Plan

- [103-shell-module-cleanup.md](/home/higorprado/nixos/docs/for-agents/plans/103-shell-module-cleanup.md)

## Baseline

- Validation gates: PASS
- 3 hosts eval: PASS
- Working tree: clean (only flake.lock modified)

## Slices

### Phase 1 — Move monitoring packages to monitoring-tools.nix

- Added `programs.btop`, `programs.bottom`, `home.packages [htop fastfetch smartmontools]` to `monitoring-tools.nix`
- Removed same from `core-user-packages.nix`
- All hosts eval: PASS. Packages still reachable via `monitoring-tools` owner.
- Commit: `refactor(shell): move monitoring packages to monitoring-tools owner`

### Phase 2 — Remove duplicate git from core-user-packages

- Removed `git` from `core-user-packages.nix` `home.packages`
- Verified git still present via `git-gh.nix` `programs.git.enable`
- `git` count in predator HM: 1 (no duplicate)
- Commit: `fix(shell): remove duplicate git from core-user-packages`

### Phase 3 — Move zed abbreviation from fish.nix to predator

- Removed `zed = "uwsm-app zeditor"` from `fish.nix` `homeManagerOnlyAbbrs`
- Added same to `predator.nix` `operatorFishAbbrs`
- Aurelius derivation changed (fish config lost the `zed` abbreviation)
- All 3 hosts eval: PASS
- Commit: `refactor(shell): move zed abbreviation to predator host owner`

### Phase 4 — Fix tui-tools indentation

- Fixed `programs.yazi` closing brace and `programs.zellij` alignment
- HM derivation unchanged (cosmetic only)
- Commit: `style(shell): fix tui-tools indentation`

### Phase 5 — Update docs

- Updated `docs/for-agents/001-repo-map.md`:
  - `core-user-packages`: updated examples (bat, eza, fd, jq instead of btop)
  - `monitoring-tools`: added smartmontools + clarified it owns packages AND config
- Commit: `docs: update repo map for shell cleanup`

### Phase 6 — Final validation

- `./scripts/run-validation-gates.sh structure`: ALL PASS
- `./scripts/check-repo-public-safety.sh`: PASS
- `nix build --no-link` predator (NixOS + HM): PASS
- `git` count in HM: 1 (single-sourced from git-gh)
- `zed` abbreviation: predator-only via `operatorFishAbbrs`
- `ls modules/features/shell/`: 9 files (8 active + 1 helper), unchanged count

## Final State

### monitoring-tools.nix — now self-contained

Owns: `programs.btop`, `programs.bottom`, `htop`, `fastfetch`, `smartmontools` + `htoprc` config.
All monitoring packages + config in one module. Name accurately describes content.

### core-user-packages.nix — clean

Shell enhancers: bat, eza, fzf.
Essential CLI: vim, nano, wget, curl, unzip, file, rsync, restic, openssh.
Data tools: fd, jq, ripgrep, sd, tree.
No more monitoring packages. No duplicate git.

### fish.nix — decoupled from host-specific tools

`zed` abbreviation moved to predator's `operatorFishAbbrs`. Shared fish config no longer
references host-specific editors.

### tui-tools.nix — clean formatting

Indentation fixed.

### What remains open

Nothing — cleanup complete.
