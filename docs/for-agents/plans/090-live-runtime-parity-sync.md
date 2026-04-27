# Live Runtime Parity Sync for Waybar, Notifications, Clipboard, and Hyprland

## Goal

Make the tracked repo reflect the current working live desktop state on `predator` for the surfaces we have actively tuned in this conversation: Waybar, clipboard picker, notification controls/Mako behavior, and Hyprland user dotfiles. The execution model for this work is live-first: inspect and, when needed, edit the live runtime files first, then sync those results back into repo-owned sources.

## Scope

In scope:
- sync live Waybar config/style/scripts back into repo sources
- sync live notification control scripts and Mako behavior back into repo owners
- inventory and sync live Hyprland user dotfiles back into repo-owned templates/sources
- preserve the current modular live Hyprland layout if that is what the user is actually running
- add parity validation so repo-vs-live drift is explicit for these surfaces

Out of scope:
- changing unrelated desktop features not touched in this thread
- broad visual redesigns beyond preserving the current live state
- private host/user files under `private/**`
- non-desktop mutable configs not requested here

## Current State

- Recent desktop work has been applied partly in repo files and partly in live mutable files under `~/.config`.
- Waybar mutable/copy-once surfaces currently live under:
  - `~/.config/waybar/config`
  - `~/.config/waybar/style.css`
  - `~/.config/waybar/scripts/*.sh`
- Repo owners for those surfaces currently live under:
  - `config/apps/waybar/config`
  - `config/apps/waybar/style.css`
  - `config/apps/waybar/scripts/*.sh`
  - provisioned by `modules/features/desktop/waybar.nix`
- Live Waybar still differs from repo in at least:
  - `config/apps/waybar/config` vs `~/.config/waybar/config`
  - `config/apps/waybar/style.css` vs `~/.config/waybar/style.css`
- Live Mako config is currently a writable runtime file at:
  - `~/.config/mako/config`
- Repo owner for Mako behavior remains:
  - `modules/features/desktop/mako.nix`
- Live Hyprland is no longer represented only by a single minimal `user.conf`.
  Live runtime currently uses modular dotfiles under:
  - `~/.config/hypr/appearance.conf`
  - `~/.config/hypr/binds.conf`
  - `~/.config/hypr/env.conf`
  - `~/.config/hypr/input.conf`
  - `~/.config/hypr/layout.conf`
  - `~/.config/hypr/monitors.conf`
  - `~/.config/hypr/rules.conf`
  - `~/.config/hypr/startup.conf`
  - `~/.config/hypr/user.conf`
  - `~/.config/hypr/scripts/*.sh`
- Repo currently provisions only:
  - `config/desktops/hyprland-standalone/hyprland.conf` -> `~/.config/hypr/user.conf`
  via `modules/desktops/hyprland-standalone.nix`
- Therefore repo-vs-live parity is currently incomplete for Hyprland and partially incomplete for Waybar/Mako.

## Desired End State

- Repo sources match the current working live desktop state for Waybar, clipboard picker, notification controls, and Hyprland user dotfiles.
- The repo explicitly owns the same modular Hyprland layout the live system is using, or documents any intentional gap.
- Provisioning logic matches the chosen source layout instead of silently depending on ad-hoc live-only files.
- Live-first workflow is respected throughout execution: inspect/edit live first, then sync repo from live, not the reverse.
- Validation exists for the requested surfaces so future drift is easier to detect.

## Phases

### Phase 0: Baseline live-vs-repo inventory

Targets:
- live files under `~/.config/waybar/**`
- live files under `~/.config/mako/config`
- live files under `~/.config/hypr/**`
- repo owners under `config/apps/waybar/**`, `modules/features/desktop/mako.nix`, `config/desktops/hyprland-standalone/**`, `modules/desktops/hyprland-standalone.nix`

Changes:
- no semantic changes yet
- capture a parity inventory showing:
  - which files are identical
  - which files differ
  - which live files have no repo owner yet
  - which repo files no longer match live reality
- explicitly record which surfaces are mutable/copy-once and must be treated live-first

Validation:
- `git status --short`
- `diff -u` between live and repo for all in-scope Waybar files
- inventory of `~/.config/hypr/*.conf` and `~/.config/hypr/scripts/*`
- inventory of the generated/live Mako config contents

Diff expectation:
- none yet; only inventory clarity

Commit target:
- none

### Phase 1: Sync live Waybar and clipboard surfaces back into repo

Targets:
- `config/apps/waybar/config`
- `config/apps/waybar/style.css`
- `config/apps/waybar/scripts/active-window.sh`
- `config/apps/waybar/scripts/clipboard-history.sh`
- `config/apps/waybar/scripts/mako.sh`
- `config/apps/waybar/scripts/mako-dnd.sh`
- `config/apps/waybar/scripts/mako-clear.sh`
- `modules/features/desktop/waybar.nix`

Changes:
- copy the live Waybar files back into the repo verbatim where that matches the desired source of truth
- keep provisioning declarations aligned with the actual live-owned script set
- avoid restyling; parity first

Validation:
- `bash -n` on all Waybar scripts
- JSON parse of `config/apps/waybar/config`
- `./scripts/run-validation-gates.sh structure`
- live-vs-repo diffs for Waybar go to zero

Diff expectation:
- repo mirrors the currently working live Waybar/clipboard/notifier control setup

Commit target:
- `chore(desktop): sync live waybar and clipboard state`

### Phase 2: Reconcile live Mako behavior back into declarative owner

Targets:
- `~/.config/mako/config` as runtime reference
- `modules/features/desktop/mako.nix`
- any related Waybar notifier-control scripts if needed

Changes:
- translate the working live Mako behavior into the declarative owner without changing behavior
- preserve the current good semantics:
  - left click only toggles DND
  - right click dismisses everything
  - Starship command-finished notifications still notify normally
  - Starship command-finished notifications do not enter history after expiry
- document any intentional limitation that remains when DND is toggled

Validation:
- build the HM activation package and inspect the generated `.config/mako/config`
- compare generated Mako config to the live runtime file for the in-scope criteria/options
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- declarative Mako owner matches the good live runtime behavior

Commit target:
- `fix(desktop): sync live mako behavior into module owner`

### Phase 3: Import modular live Hyprland dotfiles into repo ownership

Targets:
- live `~/.config/hypr/*.conf`
- live `~/.config/hypr/scripts/*.sh`
- repo path to be introduced under `config/desktops/hyprland-standalone/`
- `modules/desktops/hyprland-standalone.nix`

Changes:
- mirror the live Hyprland modular file layout into the repo
- replace the current minimal single-file stub approach with provisioning that reflects the live modular setup
- preserve the live sourcing order from `user.conf`
- decide whether repo should own:
  - `user.conf` plus all sourced files, and
  - helper scripts under `scripts/`
- keep files copy-once/mutable where appropriate, but ensure repo templates actually represent the live state

Validation:
- structural diff between live `~/.config/hypr` and repo-owned counterparts
- `./scripts/run-validation-gates.sh structure`
- host/home-manager build for `predator`

Diff expectation:
- repo gains explicit ownership of the Hyprland runtime the user is actually running

Commit target:
- `refactor(desktop): sync live hyprland dotfiles into repo`

### Phase 4: Parity verification and drift guard

Targets:
- all in-scope repo/live surfaces
- optionally a small script or documented workflow under `scripts/` or docs if justified

Changes:
- add a focused parity check or documented command sequence for:
  - Waybar config/style/scripts
  - Mako generated/live config
  - Hyprland live modular files vs repo sources
- if a script is added, keep it narrow and host-user aware without private leakage

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- any new parity check script on the current live machine

Diff expectation:
- parity work becomes reproducible instead of one-off

Commit target:
- `test(desktop): add live parity checks for mutable desktop files`

## Risks

- Live mutable files may include user-only experimentation that should not all become canonical repo state.
- Hyprland runtime files may reference local scripts or assumptions not yet represented in repo structure.
- Generated HM files can differ slightly from handwritten live files even when behavior is equivalent; the plan must distinguish semantic parity from byte-for-byte provenance when needed.
- Syncing live-first without a careful inventory can accidentally copy transient hacks into the repo.

## Definition of Done

- Repo reflects the current live state for the requested Waybar, clipboard, notifications, and Hyprland surfaces.
- Any remaining intentional live-only differences are explicitly documented.
- Declarative owners and mutable runtime files no longer disagree silently for the in-scope surfaces.
- Validation passes after the sync work.
- The resulting repo can be used as the trustworthy source for rebuilding these desktop surfaces.
