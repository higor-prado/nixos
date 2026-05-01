# Shell Module Cleanup

## Goal

Fix fragmented ownership in `shell/`: make `monitoring-tools.nix` self-contained
(packages + config in one owner), remove the duplicate `git` package, relocate
the host-specific `zed` abbreviation from shared `fish.nix` to predator's
`operatorFishAbbrs`, and fix cosmetic indentation in `tui-tools.nix`.

## Scope

In scope:

- Move monitoring packages (`htop`, `btop`, `bottom`, `fastfetch`, `smartmontools`
  - their `programs.*`) from `core-user-packages.nix` to `monitoring-tools.nix`
- Remove duplicate `git` from `core-user-packages.nix` (already provided by `git-gh.nix`)
- Move `zed = "uwsm-app zeditor"` abbreviation from `fish.nix` to predator's
  `operatorFishAbbrs` (Zed is predator-only)
- Fix indentation in `tui-tools.nix`
- Update `docs/for-agents/001-repo-map.md` — `monitoring-tools` description
  already mentions htop/btop/bottom/fastfetch; keep text but ensure accuracy

Out of scope:

- Renaming `terminal-tmux.nix` (kept for now — cosmetic, impacts 3 hosts)
- Changing any packages or configuration behavior
- Changing fish abbreviations beyond the `zed` relocation
- Reorganizing `core-user-packages.nix` beyond the removals
- Touching other categories

## Current State

### monitoring-tools.nix — fragmented ownership

```nix
# monitoring-tools.nix — ONLY has htop CONFIG
flake.modules.homeManager.monitoring-tools = { ... }: {
  xdg.configFile."htop/htoprc".source = builtins.path { ... };
};

# core-user-packages.nix — has the actual MONITORING PACKAGES
flake.modules.homeManager.core-user-packages = { pkgs, ... }: {
  programs.btop = { enable = true; package = pkgs.btop-cuda; };
  programs.bottom.enable = true;
  home.packages = with pkgs; [ ... htop fastfetch smartmontools ... ];
};
```

The name `monitoring-tools` implies it owns monitoring tools. It doesn't.

### git duplication

- `core-user-packages.nix`: `pkgs.git` in `home.packages`
- `git-gh.nix`: `programs.git.enable = true` (HM module auto-installs the package)

Result: `git` appears twice in user profile.

### zed abbreviation in shared fish.nix

```nix
# fish.nix — homeManagerOnlyAbbrs
zed = "uwsm-app zeditor";  # Zed is only on predator!
```

This abbreviation is dead weight on aurelius and cerebelo (they don't import
`editors-zed`). The abbreviation works (fails silently when command not found),
but it's semantically wrong — host-specific ergonomics belong in the host owner.

Predator already has `operatorFishAbbrs` — the natural home for host-specific
abbreviations.

### tui-tools.nix indentation

```nix
programs.yazi = {
  enable = true;
  shellWrapperName = "yy";
  };                           # <-- broken indent
  programs.zellij.enable = true; # <-- misaligned
};
```

Cosmetic only (Nix doesn't care about whitespace). Confuses readers.

### Import status across hosts

All 3 hosts import both `homeManager.core-user-packages` and `homeManager.monitoring-tools`.
Moving packages between them has **zero impact** on final package sets — the
total set per host is identical before and after.

## Desired End State

### monitoring-tools.nix — self-contained

```nix
flake.modules.homeManager.monitoring-tools = { pkgs, ... }: {
  programs.btop = {
    enable = true;
    package = pkgs.btop-cuda;
  };
  programs.bottom.enable = true;

  home.packages = with pkgs; [ htop fastfetch smartmontools ];

  xdg.configFile."htop/htoprc".source = builtins.path { ... };
};
```

### core-user-packages.nix — no monitoring packages, no duplicate git

```nix
flake.modules.homeManager.core-user-packages = { pkgs, ... }: {
  programs.bat.enable = true;
  programs.eza = { enable = true; enableFishIntegration = false; };
  programs.fzf.enable = true;

  home.packages = with pkgs; [
    vim nano wget curl unzip file rsync restic openssh
    fd jq ripgrep sd tree
  ];
};
```

### fish.nix — zed abbreviation removed

`homeManagerOnlyAbbrs` no longer contains `zed`.

### predator.nix — zed abbreviation added

`operatorFishAbbrs` gains `zed = "uwsm-app zeditor";`.

### tui-tools.nix — indentation fixed

```nix
programs.yazi = {
  enable = true;
  shellWrapperName = "yy";
};
programs.zellij.enable = true;
```

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval` all 3 hosts
- `git status` — confirm clean (only flake.lock modified)
- Capture current `core-user-packages.nix` and `monitoring-tools.nix` content

### Phase 1: Move monitoring packages to monitoring-tools.nix

Targets:

- `modules/features/shell/monitoring-tools.nix` — add packages + programs
- `modules/features/shell/core-user-packages.nix` — remove same

Changes (`monitoring-tools.nix`):

- Add `programs.btop = { enable = true; package = pkgs.btop-cuda; };`
- Add `programs.bottom.enable = true;`
- Add `home.packages = with pkgs; [ htop fastfetch smartmontools ];`

Changes (`core-user-packages.nix`):

- Remove `programs.btop` block
- Remove `programs.bottom.enable = true;`
- Remove `htop`, `fastfetch`, `smartmontools` from `home.packages`

Validation:

- `nix eval` predator — confirm HM derivation evaluates
- Verify packages are still present in predator's home.packages (now via monitoring-tools)
- Aurelius and cerebelo eval — same outcome since both import both modules

Diff expectation:

- `core-user-packages.nix`: -6 lines (btop block + bottom + 3 packages)
- `monitoring-tools.nix`: +8 lines (programs + packages)

Commit target:

- `refactor(shell): move monitoring packages to monitoring-tools owner`

### Phase 2: Remove duplicate `git` from core-user-packages.nix

Targets:

- `modules/features/shell/core-user-packages.nix`

Changes:

- Remove `git` from `home.packages` list

Validation:

- `nix eval` predator — `git` still present via `git-gh.nix`
- Grep predator's home.packages for `git` — should appear once (from git-gh HM module)

Diff expectation:

- `core-user-packages.nix`: -1 line

Commit target:

- `fix(shell): remove duplicate git from core-user-packages`

### Phase 3: Move zed abbreviation from fish.nix to predator

Targets:

- `modules/features/shell/fish.nix` — remove `zed` from `homeManagerOnlyAbbrs`
- `modules/hosts/predator.nix` — add `zed` to `operatorFishAbbrs`

Changes (`fish.nix`):

- Remove `zed = "uwsm-app zeditor";` from `homeManagerOnlyAbbrs`

Changes (`predator.nix`):

- Add `zed = "uwsm-app zeditor";` to `operatorFishAbbrs`

Validation:

- `nix eval` predator — fish abbreviations still include `zed`
- `nix eval` aurelius, cerebelo — fish abbreviations no longer include `zed`
- Confirm no other host had `zed` abbr (only predator has it)

Diff expectation:

- `fish.nix`: -1 line
- `predator.nix`: +1 line

Commit target:

- `refactor(shell): move zed abbreviation to predator host owner`

### Phase 4: Fix tui-tools.nix indentation

Targets:

- `modules/features/shell/tui-tools.nix`

Changes:

```diff
-        };
-        programs.zellij.enable = true;
-      };
+      };
+      programs.zellij.enable = true;
+    };
```

Validation:

- `nix eval` predator — confirms no semantic change
- Visual review: `programs.zellij` correctly aligned with `programs.yazi` and `programs.lazygit`

Diff expectation:

- `tui-tools.nix`: indentation-only diff, 3 lines shifted

Commit target:

- `style(shell): fix tui-tools indentation`

### Phase 5: Update docs

Targets:

- `docs/for-agents/001-repo-map.md`

Changes:

- Line 56: `core-user-packages.nix` description — remove monitoring tools mention
  (htop, btop, bottom, fastfetch no longer there)
- Line 58: `monitoring-tools.nix` description — already says "htop, btop, bottom, fastfetch",
  but verify it's accurate. The description was already correct (aspirational) and
  now matches reality.

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh` — confirm no stale paths

Commit target:

- `docs: update repo map for shell cleanup`

### Phase 6: Final validation

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `nix eval` all 3 hosts
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- Verify monitoring packages present in predator derivation (via monitoring-tools owner)
- Verify `git` appears exactly once in predator derivation
- Verify `zed` abbreviation in predator fish config, absent from aurelius/cerebelo
- `ls modules/features/shell/` — same 9 files (8 active + 1 helper)

Diff expectation:

- Only files listed in this plan should change

## Risks

- **Zero host import changes**: All 3 hosts import both `core-user-packages` and
  `monitoring-tools`. Moving packages between them is transparent to hosts.
- **`smartmontools` placement**: Currently in `core-user-packages`. Moving to
  `monitoring-tools` groups it with other system health tools. `smartmontools`
  is also in `core-user-packages` for `smartctl` binary access. Keeping it with
  `smartd` config (in `system/maintenance-smartd.nix`) would be more logical,
  but `monitoring-tools` is HM and `maintenance-smartd` is NixOS — cross-boundary
  move out of scope.
- **`zed` abbreviation on other hosts**: Aurelius and cerebelo previously had the
  `zed` abbreviation from shared `fish.nix` but no `editors-zed` import. The
  abbreviation silently failed when invoked. Removing it is a no-op.

## Definition of Done

- [ ] `monitoring-tools.nix` owns all monitoring packages + htop config
- [ ] `core-user-packages.nix` no longer has monitoring packages
- [ ] `git` no longer duplicated in `core-user-packages.nix`
- [ ] `zed` abbreviation lives in `predator.nix` `operatorFishAbbrs`, not in `fish.nix`
- [ ] `tui-tools.nix` indentation fixed
- [ ] `docs/for-agents/001-repo-map.md` updated
- [ ] `nix eval` all 3 hosts passes
- [ ] `nix build --no-link` predator (NixOS + HM) passes
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] `./scripts/check-repo-public-safety.sh` passes
- [ ] Monitoring packages reachable via `monitoring-tools` owner on all hosts
- [ ] `git` single-sourced from `git-gh.nix`
- [ ] `zed` abbreviation predator-only
