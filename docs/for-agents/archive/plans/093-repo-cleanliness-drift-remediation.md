# Repo Cleanliness and Mutable Drift Remediation

## Goal

Remediate the repo audit findings without regressions: remove hidden tracked-state traps, reconcile mutable live desktop config back into repo ownership, and keep the repository documentation and validation model aligned with the current Hyprland-only runtime. For mutable desktop surfaces, the live system is the operational source of truth, except for the Hyprland environment ownership cleanup where the repo/Nix session bootstrap remains authoritative.

## Scope

In scope:
- fix ignored-but-important files that are currently invisible to Git-based flakes
- reconcile `config/devenv-templates/*/.envrc` so devenv templates work from `git+file` and published flakes
- fix `.gitignore` so root local `reports/` remains ignored without hiding archived agent reports
- decide whether existing ignored historical reports under `docs/for-agents/archive/reports/` should be tracked or deleted
- reconcile live Hyprland Lua config back to `config/desktops/hyprland-standalone/` using live-first workflow
- preserve the repo-side environment/session cleanup in `config/desktops/hyprland-standalone/modules/env.lua`; do not blindly copy live env drift that reintroduces hardcoded toolkit/theme/cursor/session variables
- reconcile live Waybar config back to `config/apps/waybar/` using live-first workflow
- remove stale live-only backup/runtime junk after confirming it has no owner value
- remove or archive deprecated repo payloads that are no longer provisioned, especially `config/desktops/hyprland-standalone/hyprland.conf`
- pin `pkgs/predator-tui.nix` to an immutable source revision
- close or refresh the active notification remediation docs after checking current Mako runtime state
- run validation gates after each meaningful slice

Out of scope:
- reading or editing real private files under `private/users/*` or `private/hosts/*`
- broad redesign of Hyprland, Waybar, notification UX, or theme architecture
- changing active desktop selection away from Hyprland
- replacing Mako or Waybar unless a separate explicit plan is opened
- applying global `statix` style rewrites unrelated to concrete findings
- changing `keyrs` behavior or keyboard injection policy
- switching/rebuilding the live system unless explicitly requested for runtime acceptance

## Current State

Recent validated state:
- worktree was clean at audit time
- full validation passed at `a82e50b chore(docs): refresh repo map and archive completed plans`
- `./scripts/run-validation-gates.sh` passed
- `./scripts/check-repo-public-safety.sh` passed
- `./scripts/check-nix-deprecations.sh` passed
- `./scripts/check-flake-tracked.sh` passed
- `./scripts/check-declarative-paths.sh` passed
- `deadnix` reported no actionable failures for `flake.nix modules hardware lib pkgs`
- `shellcheck -x` on tracked shell scripts reported no failures

Important repo rules:
- mutable/copy-once desktop surfaces must be treated live-first, then synced live to repo
- no real private override files may be read or committed
- non-trivial work must be split into small validated slices
- active plans live in `docs/for-agents/plans/`; active progress logs live in `docs/for-agents/current/`
- completed plans/logs should move to archive

Audit findings to remediate:

1. Hidden `.envrc` files for devenv templates:
   - local files exist under `config/devenv-templates/{go,javascript,lua,python,rust}/.envrc`
   - they are ignored by a global Git ignore rule
   - `git+file` template paths currently contain only `devenv.nix`, so generated projects miss `use devenv`

2. Archived reports hidden by `.gitignore`:
   - `.gitignore` has `reports/`, which also ignores nested `docs/for-agents/archive/reports/`
   - ignored files currently include historical reports such as `001-home-vs-system-package-placement-report.md`, `003-post-reorg-reassessment-report.md`, `004-cross-host-post-reorg-analysis-report.md`, and `078-waybar-tray-startup-diagnosis-report.md`

3. Mutable desktop drift:
   - live Hyprland differs from repo in `hyprland.lua`, `modules/appearance.lua`, `modules/env.lua`, and `modules/rules.lua`
   - live has generated `session-bootstrap.lua`, which is expected to be HM-generated and not copied as a source payload
   - repo has deprecated `config/desktops/hyprland-standalone/hyprland.conf`, which is no longer provisioned
   - live Waybar differs from repo in `config`, `style.css`, and `scripts/clipboard-history.sh`
   - live Waybar has extra files `catppuccin.css`, `config.bak2`, and `scripts/waypaper.sh`

4. Source pinning issue:
   - `pkgs/predator-tui.nix` fetches from GitHub with `rev = "main"`
   - `linuwu-sense` already follows the preferred immutable commit pattern

5. Notification docs state drift:
   - `docs/for-agents/current/089-notification-daemon-remediation-progress.md` contains an absolute path link
   - it says Mako live config was converted to a writable file, but current runtime inspection showed `~/.config/mako/config` is a Home Manager store symlink
   - plan/log 089 may be complete, stale, or still active; this must be decided explicitly

6. Statix style noise:
   - `statix` reports many style warnings, mostly empty patterns and repeated dotted keys
   - these are not build blockers and should not be mixed into this remediation except where a touched file can be cleaned safely

## Desired End State

- `git status --short` is clean after the work is committed.
- `config/devenv-templates/*/.envrc` is intentionally tracked or intentionally absent; `git+file` templates include the intended files.
- root local `reports/` remains ignored, but `docs/for-agents/archive/reports/` is no longer accidentally hidden by ignore rules.
- historical archived reports are either tracked or explicitly removed; there are no surprise ignored docs under the official archive path.
- Hyprland live/repo parity is resolved for source-owned Lua files.
- `modules/env.lua` does not regress by reintroducing hardcoded env/session/theme/cursor variables that should be owned by Nix/Home Manager/session bootstrap.
- Waybar live/repo parity is resolved for source-owned files.
- stale live-only files such as Waybar backups are removed only after confirming they are not needed.
- deprecated non-provisioned Hyprland payloads are removed from repo sources.
- `predator-tui` source is pinned to an immutable revision.
- notification remediation docs are either current and active or archived as historical.
- validations pass after each slice and at final state.

## Phases

### Phase 0: Baseline and guardrails

Targets:
- no semantic repo changes except this plan/log track

Changes:
- confirm current branch and clean worktree
- capture exact live-vs-repo diff inventories for Hyprland and Waybar
- capture ignored file inventory for reports and devenv templates
- capture current Mako live status
- capture current `predator-tui` source revision candidate from upstream

Validation:
- `git status --short`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `git status --ignored --short docs/for-agents/archive/reports config/devenv-templates`
- `diff -qr ~/.config/hypr config/desktops/hyprland-standalone`
- `diff -qr ~/.config/waybar config/apps/waybar`

Diff expectation:
- none yet, except active docs for the plan/log track

Commit target:
- none, unless committing only the plan/log track as `chore(agents): add repo cleanliness remediation plan`

### Phase 1: Fix ignored devenv template files

Targets:
- `.gitignore`
- `config/devenv-templates/go/.envrc`
- `config/devenv-templates/javascript/.envrc`
- `config/devenv-templates/lua/.envrc`
- `config/devenv-templates/python/.envrc`
- `config/devenv-templates/rust/.envrc`

Changes:
- add a narrow `.gitignore` exception for tracked devenv template `.envrc` files, or move the template envrc content into tracked non-ignored files if a better pattern is chosen
- track each template `.envrc` containing the intended `use devenv` payload
- verify `git+file` template outputs include `.envrc`

Validation:
- `git status --short`
- `git check-ignore -v config/devenv-templates/python/.envrc || true`
- for each template: `nix eval --raw git+file://$PWD#templates.<name>.path` then inspect that `.envrc` is present
- `nix flake metadata path:$PWD`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- `.gitignore` exception and five tracked `.envrc` files

Commit target:
- `fix(dev): track devenv template envrc files`

### Phase 2: Fix archived report ignore behavior

Targets:
- `.gitignore`
- `docs/for-agents/archive/reports/`

Changes:
- replace broad `reports/` ignore with root-scoped `/reports/`, unless another narrower ignore is preferable
- decide for each currently ignored historical report whether it is valuable history to track or local junk to delete
- if tracking, add the reports after public safety passes
- if deleting, remove only ignored historical docs that are confirmed not part of the intended archive

Validation:
- `git status --ignored --short docs/for-agents/archive/reports reports`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- `.gitignore` root-scope fix
- either added archived reports or deletion from filesystem with no tracked diff for the deleted ignored files

Commit target:
- `fix(docs): stop ignoring archived agent reports`

### Phase 3: Reconcile Hyprland mutable runtime drift

Targets:
- live first:
  - `~/.config/hypr/hyprland.lua`
  - `~/.config/hypr/modules/appearance.lua`
  - `~/.config/hypr/modules/env.lua`
  - `~/.config/hypr/modules/rules.lua`
  - `~/.config/hypr/scripts/screenshot.sh`
- repo sync target:
  - `config/desktops/hyprland-standalone/hyprland.lua`
  - `config/desktops/hyprland-standalone/modules/appearance.lua`
  - `config/desktops/hyprland-standalone/modules/env.lua`
  - `config/desktops/hyprland-standalone/modules/rules.lua`
  - `config/desktops/hyprland-standalone/scripts/screenshot.sh`
  - `modules/desktops/hyprland-standalone.nix`

Changes:
- treat live Hyprland visual/rule behavior as correct
- copy live `hyprland.lua`, `appearance.lua`, and `rules.lua` to repo after inspection
- handle `env.lua` specially:
  - do not blindly copy live env drift
  - preserve repo cleanup that lets NixOS/Home Manager/session bootstrap own toolkit, theme, cursor, and desktop-session variables
  - if live needs runtime changes, apply the minimal live edit first, reload Hyprland, then sync the corrected live file to repo
- keep `session-bootstrap.lua` as generated runtime, not a repo source payload
- remove `config/desktops/hyprland-standalone/hyprland.conf` if it is confirmed no longer provisioned

Validation:
- `bash -n ~/.config/hypr/scripts/screenshot.sh config/desktops/hyprland-standalone/scripts/screenshot.sh`
- `hyprctl reload`
- `hyprctl configerrors`
- `diff -qr ~/.config/hypr config/desktops/hyprland-standalone` with documented expected exclusions only (`session-bootstrap.lua`, removed/deprecated files if any)
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Hyprland source files synced from live, with env exception intentionally resolved
- deprecated `hyprland.conf` removed if confirmed

Commit target:
- `fix(hyprland): reconcile live lua config drift`
- optional separate commit: `chore(hyprland): remove deprecated hyprland conf payload`

### Phase 4: Reconcile Waybar mutable runtime drift

Targets:
- live first:
  - `~/.config/waybar/config`
  - `~/.config/waybar/style.css`
  - `~/.config/waybar/scripts/clipboard-history.sh`
  - `~/.config/waybar/scripts/waypaper.sh`
  - `~/.config/waybar/catppuccin.css`
  - `~/.config/waybar/config.bak2`
- repo sync target:
  - `config/apps/waybar/config`
  - `config/apps/waybar/style.css`
  - `config/apps/waybar/scripts/clipboard-history.sh`
  - possibly `config/apps/waybar/scripts/waypaper.sh` if live script is still used and should be owned

Changes:
- inspect each live-only file before copying or deleting
- treat live Waybar behavior as correct unless inspection shows backup/runtime-only junk
- decide whether `catppuccin.css` should remain generated by Catppuccin/Home Manager or become tracked payload
- delete `~/.config/waybar/config.bak2` only if confirmed as stale local backup
- sync source-owned live files back to repo

Validation:
- `bash -n` on all Waybar scripts that are shell scripts
- `waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css` smoke if safe, or restart Waybar user service if already managed
- `diff -qr ~/.config/waybar config/apps/waybar` with documented expected exclusions only
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Waybar config/style/script synced from live
- optional added script if `waypaper.sh` is a real runtime dependency
- no tracked backup files

Commit target:
- `fix(waybar): reconcile live mutable config drift`

### Phase 5: Pin predator-tui source

Targets:
- `pkgs/predator-tui.nix`

Changes:
- resolve current upstream `main` to a concrete commit SHA
- replace `rev = "main"` with the commit SHA
- update hash only if necessary
- keep package behavior unchanged

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- one-line `rev` change, hash unchanged if the current hash corresponds to that commit

Commit target:
- `fix(pkgs): pin predator-tui source revision`

### Phase 6: Resolve notification remediation doc state

Targets:
- `docs/for-agents/plans/089-notification-daemon-remediation.md`
- `docs/for-agents/current/089-notification-daemon-remediation-progress.md`
- possibly archive paths under `docs/for-agents/archive/plans/` and `docs/for-agents/archive/log-tracks/`

Changes:
- inspect current live Mako service/config status
- decide if plan 089 is still active:
  - if active, update progress with current facts and replace absolute path link with a repo-relative or non-absolute link
  - if complete/stale, move plan/log to archive and record final state
- do not change notification behavior in this phase unless explicitly requested

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- docs-only

Commit target:
- `chore(docs): resolve notification remediation state`

### Phase 7: Final validation and report

Targets:
- entire repo
- new final report under the agent archive reports directory if requested by the human

Changes:
- run final gates
- record what changed, what was intentionally left alone, and any remaining low-priority style issues
- create final report only after remediation is done and the human wants it persisted

Validation:
- `git status --short`
- `nix flake metadata path:$PWD`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`
- `git diff --check`

Diff expectation:
- no unstaged changes
- no untracked source files except intentionally ignored local cache/private/runtime artifacts

Commit target:
- final report commit only if a report file is created: `docs(agents): add repo cleanliness remediation report`

## Risks

- Blindly copying live `env.lua` would reintroduce environment/session/cursor/theme ownership drift that was recently fixed.
- Blindly deleting ignored reports could lose useful historical context.
- Broad `.gitignore` changes could accidentally expose private or local artifacts; safety gate must run before any commit involving ignore changes.
- Waybar live config may contain runtime-only generated files or stale backups; these must not be tracked blindly.
- Mutable copy-once configs can pass Nix builds while live runtime remains divergent; runtime parity checks are mandatory.
- `predator-tui` pinning may require hash updates if the current hash does not match the resolved commit.
- Notification docs might represent unfinished user acceptance; archiving them without confirmation could hide active work.

## Definition of Done

- All high findings from the audit are resolved or explicitly deferred with human approval.
- Devenv templates include intended `.envrc` files when evaluated through `git+file`.
- Official archived reports are no longer accidentally hidden by `.gitignore`.
- Hyprland source-owned files have a documented live/repo parity state, with `env.lua` ownership preserved correctly.
- Waybar source-owned files have a documented live/repo parity state.
- Deprecated Hyprland payloads are removed or intentionally documented.
- `predator-tui` no longer uses floating `main`.
- Active notification plan/log state is accurate.
- `./scripts/run-validation-gates.sh` passes.
- `./scripts/check-repo-public-safety.sh` passes.
- Final work is split into focused commits following repo conventions.
