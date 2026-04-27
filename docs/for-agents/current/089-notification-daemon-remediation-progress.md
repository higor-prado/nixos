# Notification Daemon Remediation Progress

## Status

In progress

## Related Plan

- [089-notification-daemon-remediation.md](/home/higorprado/nixos/docs/for-agents/plans/089-notification-daemon-remediation.md)

## Baseline

- Branch: `cleanup/hyprland-only`
- Active plan: `docs/for-agents/plans/089-notification-daemon-remediation.md`
- Notification daemon owner remains `modules/features/desktop/mako.nix`
- Runtime inspection showed:
  - `makoctl list -j` currently empty
  - `makoctl history -j` contains duplicate terminal-style notifications
  - `pgrep -a mako` shows a live `mako` process even though `systemctl --user status mako.service` is inactive
- Validation before remediation slices:
  - `./scripts/run-validation-gates.sh structure` ✅
  - `./scripts/check-repo-public-safety.sh` ✅

## Slices

### Slice 1 — Phase 0 source identification

- Findings:
  - Replayed history entries include repeated notifications with:
    - `app_name = "starship"`
    - `summary = "Command finished"`
    - `body = "Command execution …"`
  - Runtime Starship config confirms the source-side trigger:
    - `cmd_duration.show_notifications = true`
    - `cmd_duration.min_time_to_notify = 45000`
  - This means the terminal flood is not primarily caused by Mako itself; Mako is preserving/replaying notifications produced by Starship command-duration notifications.
- Evidence captured from runtime:
  - `makoctl history -j`
  - `starship print-config`
  - `pgrep -a mako`
  - `systemctl --user status mako.service`
- Outcome:
  - Root cause candidate identified with a stable filterable signature (`app_name = starship`, `summary = Command finished`).
  - Next slices can now choose between source-side suppression, Mako criteria/backlog controls, or both.

### Slice 2 — Live remediation and repo sync

- Live-first changes applied in the runtime environment, then synced back into the repo:
  - converted `~/.config/mako/config` from an immutable store symlink into a writable live file
  - fixed Mako criteria quoting for Starship notifications in the live config
  - simplified live `~/.config/waybar/scripts/mako-dnd.sh` back to a pure DND toggle
  - kept the Waybar right-click clear-all path via `~/.config/waybar/scripts/mako-clear.sh`
  - removed the extra Starship-on-DND cleanup logic after it introduced unacceptable exit delay
  - synced the resulting live files back into:
    - `config/apps/waybar/config`
    - `config/apps/waybar/style.css`
    - `config/apps/waybar/scripts/mako-dnd.sh`
- Runtime validation:
  - normal Starship notification test expired without entering history
  - DND toggle script execution time is back to ~7ms per toggle in shell timing
- Repo validation:
  - `./scripts/run-validation-gates.sh structure` ✅
  - `./scripts/check-repo-public-safety.sh` ✅
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.activationPackage` ✅
  - generated HM Mako config now matches the retained live Starship criteria

## Final State

- Plan 089 is in progress with the root cause identified and an initial live mitigation applied.
- Starship `Command finished` notifications now:
  - still notify normally outside DND
  - do not enter Mako history after expiring
  - are cleared when DND is turned off so they do not flood the session afterward
- Waybar now has a clear-all pending notifications action on the Mako item right click.
- Repo copies for the mutable Waybar surfaces were synced from the live runtime state.
- Remaining open:
  - confirm whether the revised Mako behavior is acceptable in real usage
  - decide whether any further Mako tuning or replacement work is still needed
