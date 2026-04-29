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

Status: not started

Planned changes:
- inspect live diffs
- sync live-correct Hyprland behavior to repo
- handle `env.lua` as the explicit exception: repo/Nix session ownership wins over stale live env drift
- remove deprecated `hyprland.conf` only after confirming no provisioning path uses it

Validation to record:
- `hyprctl reload`
- `hyprctl configerrors`
- `diff -qr ~/.config/hypr config/desktops/hyprland-standalone` with expected exclusions documented
- Home Manager build for predator user
- structure gate

Commit target:
- `fix(hyprland): reconcile live lua config drift`
- optional: `chore(hyprland): remove deprecated hyprland conf payload`

### Slice 4 — Waybar live/repo drift reconciliation

Status: not started

Planned changes:
- inspect live Waybar diffs
- sync live-correct Waybar config/style/scripts into repo
- decide whether live-only `waypaper.sh` belongs in repo
- remove stale backup file `config.bak2` only if confirmed junk
- keep generated/theme files out of repo unless they are source-owned

Validation to record:
- `bash -n` on shell scripts
- Waybar smoke/restart if safe
- `diff -qr ~/.config/waybar config/apps/waybar` with expected exclusions documented
- Home Manager build for predator user
- structure gate

Commit target:
- `fix(waybar): reconcile live mutable config drift`

### Slice 5 — predator-tui immutable pin

Status: not started

Planned changes:
- resolve current `main` to a commit SHA
- replace floating `rev = "main"`
- update hash only if needed

Validation to record:
- Home Manager build for predator user
- system build for predator
- structure gate

Commit target:
- `fix(pkgs): pin predator-tui source revision`

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
