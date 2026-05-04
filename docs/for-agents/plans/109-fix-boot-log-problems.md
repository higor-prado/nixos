# Fix Boot Log Problems (predator)

## Goal

Eliminate the cascade of crashes (awww-daemon, xdg-desktop-portal-hyprland, waybar,
nm-applet, walker) triggered by DRM display reconfiguration events from `lact`, and
reduce D-Bus log noise from accumulated system generations.

## Scope

In scope:
- Remove `lact` from predator GPU config (eliminates DRM event trigger)
- Add restart rate limiting to `awww-daemon` systemd unit (prevent infinite crash loops)
- Clean up old system generations to reduce D-Bus duplicate noise
- Final validation: reboot and verify clean logs

Out of scope:
- Fixing `waybar` Glib::Dispatcher race condition (upstream bug in waybar 0.15.0)
- Fixing `xdg-desktop-portal-hyprland` use-after-free on `wl_output` destruction (upstream bug in 1.3.11)
- Fixing `bluetoothd` hci0 config race condition (minor, cosmetic)
- Fixing `nvidia` udev `mknod` race condition (cosmetic, device nodes already exist)
- Fixing `wireplumber` HOME=/var/empty on greeter session (expected behavior, no user impact)
- Fixing `gkr-pam` / PAM auth conversation failures (benign race, self-resolving)

## Current State

- `hardware/predator/hardware/gpu-nvidia.nix:3` has `services.lact.enable = true`
- `lact` daemon monitors DRM subsystem events and reloads GPU config on each event
- Each GPU reload triggers Hyprland output reconfiguration, which cascades into:
  - `awww-daemon`: BrokenPipe panic on Wayland socket → crash loop (~40 core dumps)
  - `xdg-desktop-portal-hyprland`: segfault in `wl_output` destructor (~10 core dumps)
  - `waybar`: Glib assertion failure on Dispatcher destruction (~15 core dumps)
  - `nm-applet`, `walker`: "cannot open display" failures
- `modules/features/desktop/waypaper.nix` defines `awww-daemon` unit with `Restart = "on-failure"` but no `StartLimitBurst`/`StartLimitIntervalSec` — crash loops run indefinitely
- 16 old system generations in `/nix/store/` cause ~3,470 D-Bus "Ignoring duplicate name" log lines

## Desired End State

- `lact` removed from predator config — no more DRM-induced output reconfiguration cascades
- `awww-daemon` unit has restart rate limiting (max 5 attempts in 60s)
- Old system generations garbage-collected — D-Bus duplicate noise eliminated
- After reboot: zero core dumps, no crash loops, clean journal

## Phases

### Phase 0: Baseline

Validation:
- `git status` — clean working tree
- `./scripts/run-validation-gates.sh structure` — must pass
- Record current boot's core dump count for comparison

### Phase 1: Remove lact

Targets:
- `hardware/predator/hardware/gpu-nvidia.nix`

Changes:
- Delete line 3: `services.lact.enable = true;`

```diff
  { config, pkgs, ... }:
  {
-   services.lact.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
```

Rationale: `lact` monitors DRM subsystem events and reloads GPU config on every
event. Each reload causes Hyprland to reconfigure outputs, which triggers the
crash cascade in awww-daemon, xdg-desktop-portal-hyprland, and waybar. Removing
lact eliminates the trigger. GPU management (clocks, fan, power) can be done via
`nvidia-settings` or other tools if needed.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.services.lact.enable` — returns `false`
- `./scripts/run-validation-gates.sh structure` — passes

Commit target:
- `fix(hardware): remove lact to eliminate DRM event cascade causing crash loops`

### Phase 2: Add restart rate limiting to awww-daemon

Targets:
- `modules/features/desktop/waypaper.nix`

Changes:
- Add `StartLimitBurst` and `StartLimitIntervalSec` to the systemd unit

```diff
        systemd.user.services.awww-daemon = lib.mkDefault {
          Unit = {
            Description = "swww wallpaper daemon (awww-daemon)";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.awww}/bin/awww-daemon";
            Environment = [
              "HOME=%h"
              "XDG_RUNTIME_DIR=/run/user/%U"
            ];
            Restart = "on-failure";
            RestartSec = 2;
+           StartLimitBurst = 5;
+           StartLimitIntervalSec = 60;
            StandardOutput = "journal";
            StandardError = "journal";
          };
-         Install.WantedBy = [ "graphical-session.target" ];
+         Install = {
+           WantedBy = [ "graphical-session.target" ];
+         };
        };
```

Rationale: Even with lact removed, other events (monitor hot-plug, GPU driver
reload) could trigger similar cascades. Rate limiting prevents infinite crash
loops — after 5 failures in 60s, systemd stops restarting the unit and the user
can manually restart it.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.awww-daemon.Service.StartLimitBurst` — returns `5`
- `./scripts/run-validation-gates.sh structure` — passes

Commit target:
- `fix(waypaper): add restart rate limiting to awww-daemon unit`

### Phase 3: Garbage collect old generations

This is a runtime action, not a code change.

Action:
- `sudo nix-collect-garbage -d` — remove all old system generations
- `sudo nixos-rebuild switch` — rebuild with only current generation in `/nix/store/`

Rationale: 16 old system-path hashes in `/nix/store/` each register D-Bus service
files, causing ~3,470 "Ignoring duplicate name" messages per boot. Removing old
generations eliminates the duplicate paths.

Validation:
- `ls /nix/store/*-system-path/ 2>/dev/null | wc -l` — should be 1 (current only)
- After next reboot: `journalctl -b | grep -c 'Ignoring duplicate'` — should be near 0

### Phase 4: Final validation — reboot and verify

Action:
- `sudo nixos-rebuild boot` — build and install without switching
- `sudo reboot` — reboot into new config
- After reboot, verify:

Validation:
- `journalctl -b | grep -c 'dumped core'` — should be 0 (was ~80+)
- `journalctl -b | grep -c 'Ignoring duplicate'` — should be near 0 (was ~3,470)
- `journalctl -b | grep 'awww-daemon' | grep -c 'panic'` — should be 0
- `journalctl -b | grep 'xdg-desktop-po.*signal' | wc -l` — should be 0
- `systemctl --user status waybar` — should be active
- `systemctl --user status awww-daemon` — should be active
- `./scripts/run-validation-gates.sh structure` — passes

## Risks

- **lact removal loses GPU management UI.** `lact` provided fan control, clock
  management, and power limit configuration for the RTX 4060. If the user needs
  these features, alternatives include `nvidia-settings` (X11 CLI), GreenWithEnvy
  (if compatible), or direct `nvidia-smi` commands. The NVIDIA driver's built-in
  power management (`hardware.nvidia.powerManagement.enable = true`) still handles
  basic power management.
- **Rate limiting may suppress legitimate restarts.** If awww-daemon crashes 5
  times in 60s for a non-lact reason (e.g., Hyprland bug), systemd will stop
  restarting it. The user would need to manually run `systemctl --user restart
  awww-daemon`. This is preferable to infinite crash loops filling the journal.
- **GC removes rollback capability.** `nix-collect-garbage -d` removes all old
  generations, so `nixos-rebuild switch --rollback` won't work until new
  generations are created. The user should confirm the new config works before GC.

## Definition of Done

- [ ] `services.lact.enable` removed from `hardware/predator/hardware/gpu-nvidia.nix`
- [ ] `awww-daemon` unit has `StartLimitBurst = 5` and `StartLimitIntervalSec = 60`
- [ ] Old system generations garbage-collected
- [ ] Reboot shows zero core dumps in journal
- [ ] Reboot shows near-zero D-Bus duplicate messages
- [ ] `awww-daemon` and `waybar` running without crashes
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] No regressions in GPU functionality (display, Hyprland compositing)
