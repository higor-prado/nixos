# Notification Daemon Remediation

## Goal

Make desktop notifications usable again on `predator` by either tightening the current `mako` behavior or replacing it with a better-fit Wayland notification center, while preserving a small, understandable owner surface in the repo.

## Scope

In scope:
- investigate the current `mako` behavior on `predator`
- identify the source of repeated terminal completion notifications
- add an operator-safe way to clear the current backlog in one action
- decide whether `mako` criteria/modes are sufficient or whether replacement is justified
- if replacement is needed, migrate the Waybar indicator and notification controls cleanly

Out of scope:
- changing unrelated Waybar modules beyond the notification entry points
- redesigning the whole desktop theme stack
- broad keybinding churn unrelated to notification control

## Current State

- Notification daemon owner: `modules/features/desktop/mako.nix`
- Waybar entry points:
  - `config/apps/waybar/scripts/mako.sh`
  - `config/apps/waybar/scripts/mako-dnd.sh`
- `theme-base.nix` enables `catppuccin.mako`
- Current `mako` config enables history implicitly and hides notifications during `do-not-disturb`
- Runtime symptoms reported by the user:
  - passing through a finished terminal window is treated like a fresh notification
  - while notifications are disabled, these accumulate heavily
  - re-enabling notifications can dump hundreds of stale notifications back into view
- `makoctl` capabilities confirmed locally:
  - `makoctl dismiss --all`
  - `makoctl dismiss --all --no-history`
  - `makoctl list -j`
  - `makoctl history -j`
- Repo currently has no explicit notification backlog purge action and no source-specific suppression criteria

## Desired End State

- Repeated terminal completion notifications are either suppressed at source or filtered safely by criteria.
- Re-enabling notifications does not flood the user with stale backlog.
- The user has an explicit one-shot clear-all action for pending notifications.
- The Waybar notification indicator reflects the chosen daemon behavior coherently.
- If `mako` remains, its config is intentionally minimal and operationally understandable.
- If `mako` is replaced, the replacement has a clear owner and migration path.

## Phases

### Phase 0: Baseline and source identification

Targets:
- `modules/features/desktop/mako.nix`
- `config/apps/waybar/scripts/mako.sh`
- `config/apps/waybar/scripts/mako-dnd.sh`
- live runtime inspection only

Changes:
- no repo changes yet
- capture live notification samples from:
  - `makoctl list -j`
  - `makoctl history -j`
- identify the offending terminal-notification producer fields:
  - `app-name`
  - `summary`
  - `body`
  - urgency / category hints if present
- verify whether the repeat is coming from the terminal emulator, shell integration, or a command-completion helper

Validation:
- reproduce the issue once deliberately
- record one or more representative JSON samples
- confirm whether repeated items share a stable filterable signature

Diff expectation:
- none

Commit target:
- none

### Phase 1: Immediate operator controls

Targets:
- `config/apps/waybar/scripts/mako.sh`
- `config/apps/waybar/scripts/mako-dnd.sh`
- optionally a new helper under `config/apps/waybar/scripts/`
- optionally Hyprland bind owner if a dedicated clear action is added later

Changes:
- add an explicit clear-all pending action using `makoctl dismiss --all --no-history`
- decide whether the Waybar icon should support:
  - left click = toggle do-not-disturb
  - right or middle click = clear pending backlog
- optionally expose a restore-last action separately if it remains useful

Validation:
- queue several test notifications
- clear them in one action
- confirm they do not move into history when the no-history path is used

Diff expectation:
- Waybar notification controls gain a safe backlog purge path

Commit target:
- `feat(desktop): add notification backlog clear control`

### Phase 2: Mako behavior tightening

Targets:
- `modules/features/desktop/mako.nix`

Changes:
- evaluate `mako` settings for:
  - bounded `max-history`
  - `history=0` or more restrictive history semantics if acceptable
  - criteria matching for the noisy terminal source
  - tighter grouped behavior and/or source-specific timeout rules
- if the terminal completion notifications can be identified reliably, suppress or downscope only that source instead of globally weakening notifications
- make `do-not-disturb` behavior align with user expectations for backlog handling

Validation:
- trigger the previously noisy terminal completion case
- move focus across terminal windows
- confirm the same notification is not resurfaced as new
- enable/disable DND and verify backlog remains bounded and sane

Diff expectation:
- existing `mako` setup becomes operationally usable without daemon replacement

Commit target:
- `fix(desktop): tame noisy mako notification sources`

### Phase 3: Replacement decision gate

Targets:
- decision record in this plan before implementation

Changes:
- if Phase 2 succeeds, stop here and archive the plan after acceptance
- if Phase 2 fails, choose a replacement daemon/center with Wayland support and backlog UX, most likely something in the `swaync` class
- confirm feature fit before coding:
  - notification center / history browsing
  - clear-all UX
  - DND behavior
  - Waybar integration path
  - acceptable themeability

Validation:
- written comparison against the current failure modes

Diff expectation:
- none yet, only decision clarity

Commit target:
- none

### Phase 4: Replacement migration, if needed

Targets:
- `modules/features/desktop/mako.nix` or successor module
- `modules/hosts/predator.nix` if import surface changes
- Waybar notification scripts/config
- theme owner files if the replacement needs explicit theming

Changes:
- introduce the replacement module cleanly
- remove or retire `mako` wiring only after the replacement path works
- update Waybar indicator semantics to match the new daemon
- keep binds/scripts small and obvious

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`
- live runtime test on `predator`
- compare notification flood behavior before/after

Diff expectation:
- notification UX becomes centered around explicit history/clear controls instead of implicit replay

Commit target:
- `refactor(desktop): replace mako with <chosen-daemon>`

## Risks

- Over-filtering may hide useful terminal notifications entirely.
- `do-not-disturb` semantics vary by daemon; replacing `mako` could shift user expectations.
- Waybar scripts are provisioned as mutable copy-once config, so runtime parity must be checked explicitly.
- The noisy notification source may live outside the daemon itself, requiring source-side mitigation.

## Definition of Done

- A clear root cause is identified for the repeated terminal notifications.
- The user can clear all pending notifications in one action.
- Notification backlog no longer explodes during DND usage.
- Either `mako` is acceptably tamed or a replacement is implemented and validated.
- The active plan can be archived because notification behavior is operationally acceptable.
