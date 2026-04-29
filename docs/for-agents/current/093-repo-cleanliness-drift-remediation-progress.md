# Repo Cleanliness and Mutable Drift Remediation Progress

## Status

Planned

## Related Plan

- [093-repo-cleanliness-drift-remediation.md](/home/higorprado/nixos/docs/for-agents/plans/093-repo-cleanliness-drift-remediation.md)

## Baseline

- Branch: `cleanup/hyprland-only`
- HEAD at plan creation: `a82e50b chore(docs): refresh repo map and archive completed plans`
- Worktree before creating this plan/log: clean
- User constraint: create the plan and log track now; do not remediate code/config yet
- Mutable desktop rule for this remediation:
  - live runtime wins for Hyprland and Waybar behavior
  - exception: Hyprland `env.lua` must preserve the repo/Nix session ownership cleanup and must not blindly re-copy live hardcoded env/theme/cursor/session variables

Baseline validations already observed during audit:

- `./scripts/run-validation-gates.sh` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `./scripts/check-nix-deprecations.sh` ✅
- `./scripts/check-flake-tracked.sh` ✅
- `./scripts/check-declarative-paths.sh` ✅
- `deadnix --fail flake.nix modules hardware lib pkgs` ✅
- `shellcheck -x` on tracked shell scripts ✅

Baseline findings to remediate:

1. `config/devenv-templates/*/.envrc` exists locally but is ignored and missing from Git-based flake template outputs.
2. `.gitignore` pattern `reports/` hides official archived reports under `docs/for-agents/archive/reports/`.
3. Hyprland mutable live config differs from repo in:
   - `hyprland.lua`
   - `modules/appearance.lua`
   - `modules/env.lua`
   - `modules/rules.lua`
4. Waybar mutable live config differs from repo in:
   - `config`
   - `style.css`
   - `scripts/clipboard-history.sh`
   - live-only `catppuccin.css`, `config.bak2`, and `scripts/waypaper.sh`
5. `config/desktops/hyprland-standalone/hyprland.conf` is deprecated and no longer provisioned.
6. `pkgs/predator-tui.nix` uses floating `rev = "main"`.
7. Notification remediation docs may be stale and still contain an absolute `/home/higorprado/...` link.

## Slices

### Slice 0 — Plan and log track creation

Changes made:
- created active remediation plan `docs/for-agents/plans/093-repo-cleanliness-drift-remediation.md`
- created active progress log `docs/for-agents/current/093-repo-cleanliness-drift-remediation-progress.md`

Validation run:
- pending after file creation

Diff result:
- docs-only active planning surface

Commit:
- pending

### Slice 1 — Devenv template `.envrc` tracking

Status: completed

Changes made:
- added narrow `.gitignore` exception for `config/devenv-templates/*/.envrc`
- tracked `config/devenv-templates/{go,javascript,lua,python,rust}/.envrc`
- each tracked template `.envrc` contains `use devenv`

Validation run:
- `git check-ignore -v config/devenv-templates/python/.envrc || true` → repo exception now wins
- `nix eval --raw git+file://$PWD#templates.<name>.path` for `python`, `go`, `javascript`, `lua`, and `rust` → each output contains `.envrc` and `devenv.nix`
- `./scripts/run-validation-gates.sh structure` ✅

Diff result:
- `.gitignore` exception and five tracked `.envrc` files

Commit:
- pending: `fix(dev): track devenv template envrc files`

### Slice 2 — Archived report ignore fix

Status: completed

Changes made:
- changed `.gitignore` from broad `reports/` to root-scoped `/reports/`
- kept root local `reports/` ignored
- unhid and tracked the historical reports already present under `docs/for-agents/archive/reports/`

Validation run:
- `git status --ignored --short docs/for-agents/archive/reports reports` → archive reports visible, root `reports/` still ignored
- `./scripts/check-repo-public-safety.sh` ✅
- `./scripts/run-validation-gates.sh structure` ✅

Diff result:
- `.gitignore` one-line scope fix
- four archived report files added to Git tracking

Commit:
- pending: `fix(docs): stop ignoring archived agent reports`

### Slice 3 — Hyprland live/repo drift reconciliation

Status: completed

Changes made:
- synced live-correct Hyprland behavior into repo for:
  - `config/desktops/hyprland-standalone/hyprland.lua`
  - `config/desktops/hyprland-standalone/modules/appearance.lua`
  - `config/desktops/hyprland-standalone/modules/rules.lua`
- applied the repo-clean `env.lua` to live first, preserving the explicit exception where repo/Nix session ownership wins over stale live env drift
- synced corrected live `env.lua` back to repo; no repo diff remained for `env.lua`
- removed deprecated `config/desktops/hyprland-standalone/hyprland.conf` after confirming no active non-archive references/provisioning path used it

Validation run:
- `hyprctl reload` initially failed from the agent shell because `HYPRLAND_INSTANCE_SIGNATURE` was not exported
- retried with `XDG_RUNTIME_DIR=/run/user/1002` and the active socket signature from `/run/user/1002/hypr/...`; `hyprctl reload` ✅
- `hyprctl configerrors` ✅ empty
- `diff -qr ~/.config/hypr config/desktops/hyprland-standalone` → only expected live generated `session-bootstrap.lua` remained
- `bash -n ~/.config/hypr/scripts/screenshot.sh config/desktops/hyprland-standalone/scripts/screenshot.sh` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `./scripts/run-validation-gates.sh structure` ✅

Diff result:
- live/repo Hyprland Lua drift reconciled
- deprecated `hyprland.conf` removed

Commit:
- pending: `fix(hyprland): reconcile live lua config drift`

### Slice 4 — Waybar live/repo drift reconciliation

Status: completed

Changes made:
- synced live-correct Waybar files to repo:
  - `config/apps/waybar/config`
  - `config/apps/waybar/style.css`
  - `config/apps/waybar/scripts/clipboard-history.sh`
- added `config/apps/waybar/scripts/waypaper.sh` from live because both live and repo config reference it
- added Home Manager copy-once provisioning for `waypaper.sh` in `modules/features/desktop/waybar.nix`
- removed stale live backup `~/.config/waybar/config.bak2`
- kept `~/.config/waybar/catppuccin.css` untracked because it is a Catppuccin/Home Manager generated symlink

Validation run:
- `bash -n config/apps/waybar/scripts/*.sh ~/.config/waybar/scripts/*.sh` ✅
- `diff -qr ~/.config/waybar config/apps/waybar` → only expected live generated `catppuccin.css` remained
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `./scripts/run-validation-gates.sh structure` ✅

Diff result:
- Waybar mutable config/style/script drift reconciled
- missing `waypaper.sh` source/provisioning added
- no tracked backup files

Commit:
- pending: `fix(waybar): reconcile live mutable config drift`

### Slice 5 — predator-tui immutable pin

Status: completed

Changes made:
- resolved upstream `main` for `higorprado/predator-tui` to `8b3c88e15755404166c29b62afb789bcfb54d73a`
- replaced floating `rev = "main"` in `pkgs/predator-tui.nix`
- hash did not need to change

Validation run:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `rg -n 'rev = "(main|master|HEAD)"|ref = "(main|master|HEAD)"' flake.nix pkgs modules hardware --glob '*.nix' || true` → no output
- `./scripts/run-validation-gates.sh structure` ✅

Diff result:
- one-line immutable source revision pin

Commit:
- pending: `fix(pkgs): pin predator-tui source revision`

### Slice 6 — Notification remediation docs state

Status: not started

Planned changes:
- inspect current Mako runtime status
- decide whether plan/log 089 remain active
- update or archive active notification docs
- remove absolute path link from active progress doc if it remains active

Validation to record:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`

Commit target:
- `chore(docs): resolve notification remediation state`

### Slice 7 — Final validation and report

Status: not started

Planned changes:
- run full validation
- optionally create final archived report after remediation is complete

Validation to record:
- `nix flake metadata path:$PWD`
- predator stateVersion evals
- predator Home Manager build
- predator system build
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`
- `git diff --check`

Commit target:
- optional report commit if requested

## Final State

Not reached. This log track currently records the planned remediation only.
