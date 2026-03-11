# Post-Boot Machine Audit Plan

## Goal

Perform a full post-boot audit of the current `predator` state so that any issue found later during the `Noctalia` experiment can be attributed correctly.

This is a **baseline integrity audit**, not a feature change.

The target is:
- identify all meaningful errors since the last reboot,
- classify them as:
  - known/acceptable noise,
  - real current regressions,
  - unrelated historical quirks,
- leave a clean, documented baseline before introducing a new desktop component.

## Scope

Audit the machine state **since the latest boot only**.

Sources:
- systemd failed units
- user failed units
- journald logs for the current boot
- DMS / wallpaper services
- greet / session startup
- impermanence / root reset / persistence mounts
- swap
- bluetooth / desktop applets
- explicit runtime smoke signals where useful

## Non-Goals

- changing Noctalia yet
- making speculative fixes before evidence exists
- conflating old archived issues with current-boot issues

## Audit Phases

### Phase 0: Capture Boot Identity

Commands:

```bash
who -b
uptime -s
journalctl -b -n 20 --no-pager
```

Purpose:
- anchor the audit to the current boot
- confirm that all later log reads are for the same reboot window

### Phase 1: Failed Units Sweep

Commands:

```bash
systemctl --failed --no-pager
systemctl --user --failed --no-pager
```

If non-empty:
- inspect each failed unit with:

```bash
systemctl status <unit> --no-pager
systemctl --user status <unit> --no-pager
journalctl -b -u <unit> --no-pager -n 120
```

Purpose:
- identify explicit breakage first

### Phase 2: Core Persistence / Boot Integrity

Commands:

```bash
findmnt /persist
findmnt /swap
swapon --show
journalctl -b -u root-reset.service --no-pager -n 120
sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt/btrfs-top
sudo ls -1 /mnt/btrfs-top
sudo ls -1 /mnt/btrfs-top/@old-roots
sudo umount /mnt/btrfs-top
```

Purpose:
- confirm root reset executed
- confirm persistence and swap are healthy
- confirm archival of old roots is working

### Phase 3: Login / Session Path

Commands:

```bash
systemctl status greetd.service --no-pager
journalctl -b -u greetd.service --no-pager -n 120
loginctl list-sessions
loginctl session-status 1
systemctl --user status graphical-session.target --no-pager
```

Purpose:
- confirm login/session path is healthy
- detect greet/auth/session startup anomalies

### Phase 4: Desktop Runtime Stack

Commands:

```bash
systemctl --user status dms.service --no-pager
systemctl --user status dms-awww.service --no-pager
systemctl --user status awww-daemon.service --no-pager
journalctl --user -b -u dms.service --no-pager -n 120
journalctl --user -b -u dms-awww.service --no-pager -n 120
journalctl --user -b -u awww-daemon.service --no-pager -n 120
```

Also inspect the generated config:

```bash
sed -n '1,120p' ~/.config/dms-awww/config.toml
```

Purpose:
- confirm DMS baseline is clean before Noctalia testing

### Phase 5: Bluetooth / Tray / Known GUI Noise

Commands:

```bash
systemctl status bluetooth.service --no-pager
journalctl -b -u bluetooth.service --no-pager -n 120
journalctl --user -b | rg -i 'blueman|bluetooth|gtk_icon_theme_get_for_screen|AttributeError' -n
```

Purpose:
- separate harmless GUI applet noise from actual Bluetooth failures

### Phase 6: Broad Current-Boot Journal Sweep

Commands:

```bash
journalctl -b -p warning..alert --no-pager
journalctl --user -b -p warning..alert --no-pager
```

Review policy:
- ignore known benign warnings only if they are clearly explainable
- every remaining warning/error must be classified

Useful filters:

```bash
journalctl -b --no-pager | rg -i 'failed|error|warn|denied|timed out|traceback|exception'
journalctl --user -b --no-pager | rg -i 'failed|error|warn|denied|timed out|traceback|exception'
```

### Phase 7: Optional Runtime Smoke Confirmation

Use only if the baseline is still ambiguous:

```bash
./scripts/check-runtime-smoke.sh
```

Purpose:
- final sanity check, not primary source of truth

## Classification Rules

Every issue found should be classified into one of:

1. `baseline-ok`
   - no action needed

2. `known-noise`
   - real log noise, but acceptable and understood

3. `real-regression`
   - needs fixing before Noctalia

4. `defer`
   - real issue, but unrelated to current experiment and safe to postpone

## Output Expectations

By the end of the audit we should have:
- a list of failed units, ideally zero
- a list of warnings/errors since boot
- a classification for each one
- a clear statement:
  - `safe baseline for Noctalia testing`
  - or `not safe, fix these items first`

## Notes for the Agent

- Do not jump straight to fixes.
- First establish a complete current-boot baseline.
- Be strict about distinguishing:
  - current issue,
  - known harmless noise,
  - already-fixed historical issue.
