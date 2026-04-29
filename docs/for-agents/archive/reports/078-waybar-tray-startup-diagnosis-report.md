# Waybar Tray Startup Diagnosis Report

## Summary

The Waybar tray does not fail randomly. The most likely root cause is startup ordering and session-environment propagation in the `systemd --user` graph for Hyprland.

The tray host (`waybar`) and tray applets (`nm-applet`, `blueman-applet`, `udiskie`) are being started through `graphical-session.target` / `tray.target`, but that does not reliably guarantee that the Wayland session environment is ready when those services start.

As a result, some applets start too early, fail, or start in degraded mode, which makes the tray appear empty or partially populated.

## Evidence Collected

### 1. Waybar sometimes starts before Wayland session environment is available

Observed in `journalctl --user -u waybar`:

```text
waybar.service ... skipped, unmet condition check ConditionEnvironment=WAYLAND_DISPLAY
```

and later:

```text
waybar: cannot open display:
waybar: cannot open display: :0
```

This shows that Waybar restarts while the required session environment is not consistently available to the user manager.

### 2. Tray applets fail for the same reason

Observed in `systemctl --user status` and logs:

#### NetworkManager applet
```text
nm-applet: cannot open display:
```

#### Blueman applet
Blueman fails during GTK/app icon initialization after being launched without a usable display/session context.

#### Udiskie
```text
Not run within X or Wayland session.
Starting udiskie without tray icon.
```

This explains the exact symptom: Waybar may come back later, but some tray applets have already failed or started without tray integration.

### 3. Current unit topology is fragile

#### `waybar.service`
Relevant properties:
- `WantedBy=tray.target`
- `WantedBy=graphical-session.target`
- `After=graphical-session.target`
- `ConditionEnvironment=WAYLAND_DISPLAY`
- `PartOf=tray.target`
- `PartOf=graphical-session.target`

#### Tray applets
Examples: `network-manager-applet`, `blueman-applet`, `udiskie`

Relevant properties:
- `WantedBy=graphical-session.target`
- `After=graphical-session.target`
- `After=tray.target`
- some require `tray.target`

#### `tray.target`
Current definition:
```ini
[Unit]
Description=Home Manager System Tray
Requires=graphical-session-pre.target
```

This target does **not** guarantee that Waybar is actually running successfully as a tray host before applets start.

### 4. Intermittent timing matches the behavior observed by the user

The issue appears “sometimes” because it depends on timing/race conditions, especially around:
- session start
- greetd restart
- Hyprland restart/reload
- Waybar crash/restart
- user services hitting restart / start-limit behavior

### 5. Additional supporting signal

Waybar logs also showed duplicate tray registration behavior such as:

```text
Status Notifier Item ... udiskie is already registered
```

This is consistent with a tray host restarting while applets are in an inconsistent registration state.

## Technical Conclusion

The tray problem is not primarily a visual/configuration issue in Waybar’s JSON.

The most likely root cause is:

1. **systemd user services are starting before the Wayland session environment is fully propagated**, and
2. **`tray.target` does not guarantee a live tray host**, only ordering in the target graph.

In practical terms:
- Waybar is sometimes absent or failing at the moment tray applets start.
- Applets then fail hard or start without tray integration.
- When Waybar later succeeds, the tray may remain empty or incomplete.

## Most Likely Fix Direction

The next corrective step should focus on:

1. tightening startup ordering between Hyprland session readiness, Waybar, and tray applets,
2. ensuring Wayland environment variables are present before tray-related units start,
3. making tray applets resilient to early startup failures with appropriate restart behavior.

## Files/Units Involved

### Nix files
- `modules/features/desktop/waybar.nix`
- `modules/features/desktop/session-applets.nix`
- `modules/desktops/hyprland-standalone.nix`
- `config/desktops/hyprland-standalone/hyprland.conf`
- `config/apps/waybar/config`

### Runtime units
- `waybar.service`
- `tray.target`
- `network-manager-applet.service`
- `blueman-applet.service`
- `udiskie.service`
- `graphical-session.target`
- `hyprland-session.target`

## Status

Diagnosis saved for follow-up remediation planning and implementation.
