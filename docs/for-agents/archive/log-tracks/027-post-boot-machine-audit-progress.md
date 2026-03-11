# Post-Boot Machine Audit Progress

## Status

Executed on the current boot.

## Goal

Establish a clean, evidence-based machine baseline after the latest reboot before testing Noctalia.

## Audit Targets

- failed units
- current-boot system journal
- current-boot user journal
- root reset / persistence / swap
- greet / login path
- DMS baseline
- bluetooth/tray noise

## Findings

### Baseline ok

- `systemctl --failed`: `0`
- `systemctl --user --failed`: `0`
- `/persist` mounted from `@persist`
- `/swap` mounted from `@swap`
- swap active on both `zram0` and `/swap/swapfile`
- `root-reset.service` completed successfully during boot
- `greetd.service` active; one failed login attempt was followed by a successful login
- `dms.service` active
- `dms-awww.service` active
- `awww-daemon.service` active

### Known noise

- `awww-daemon.service` failed once at session start because `WAYLAND_DISPLAY` was not ready yet, then restarted successfully two seconds later
- `dms-awww.service` failed its first wallpaper apply for the same reason, then restarted successfully and remained healthy

### Outcome

`safe baseline for Noctalia testing`
