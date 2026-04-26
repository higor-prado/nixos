# Fix: Waybar not auto-starting after login (revised)

## Problem
Waybar starts via systemd (`programs.waybar.systemd.enable = true`). When the user logs out (Hyprland exits), waybar loses its Wayland connection, crashes, and systemd rapidly retries 5 times — all fail because there's no compositor. systemd marks the service as `start-limit-hit` (permanent failure). On next login, `hyprland-session.target` reactivates, but systemd does not restart failed services. Waybar stays dead.

## Root cause confirmed via investigation

- `ConditionEnvironment=WAYLAND_DISPLAY` (added by current home-manager) does **NOT** protect against this. The `WAYLAND_DISPLAY` env var persists in the systemd user manager even after the compositor dies. Confirmed via `systemctl --user show-environment`.
- Default `StartLimitBurst=5` over `StartLimitIntervalSec=10s` is too tight: 6 crashes in <1 second hits the limit.
- Known unsolved upstream issue: home-manager#7895, home-manager#3599, Hyprland#8394.
- Journal evidence (2026-04-25 17:07:17-18): "Broken pipe" crash, 6 rapid "cannot open display:" failures, then `start-limit-hit`. New Hyprland session at 17:07:28 but waybar stays dead.

## Approach: `exec-once` restart in Hyprland Nix config

Add `exec-once = systemctl --user restart waybar.service` via `wayland.windowManager.hyprland.settings` in the `hyprland.nix` home-manager module. When Hyprland starts, it tells systemd to restart waybar. `systemctl restart` clears the failure counter and starts fresh — works even in `start-limit-hit` state.

The HM-generated Hyprland config puts `settings` content before `extraConfig`, so the exec-once runs before `source = ~/.config/hypr/user.conf`. This is fine.

### Why not the previous systemd override approach

The previous plan added `StartLimitBurst=30` and `StartLimitIntervalSec=300` to the systemd service. Overengineering:
- Workaround for a systemd lifecycle issue that isn't our problem
- `exec-once` is what every non-Nix Hyprland user does — idiomatic
- The override with `lib.mkForce` on `After` is fragile

## Changes

### 1. `modules/features/desktop/waybar.nix` — remove systemd override
Remove the entire `systemd.user.services.waybar = { ... };` block (lines 14-22). File returns to:

```nix
      programs.waybar = {
        enable = true;
        systemd.enable = true;
      };
```

### 2. `modules/features/desktop/hyprland.nix` — add exec-once for waybar restart
In the `homeManager.hyprland` module, add to the existing attrset:

```nix
wayland.windowManager.hyprland.settings.exec-once = [ "systemctl --user restart waybar.service" ];
```

This is placed in the `hyprland.nix` module (not `waybar.nix`) because it's a Hyprland config directive. The waybar module already declares `systemd.enable = true` which creates the service — the exec-once just ensures it restarts on compositor launch.

## Verification
1. `nix flake metadata path:$PWD`
2. `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
3. `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
4. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
5. `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
6. Verify generated hyprland config contains exec-once: `cat ~/.config/hypr/hyprland.conf | grep waybar`
7. Verify systemd override is gone: `systemctl --user cat waybar.service` (should show only HM defaults)
8. Log out and log back in
9. Verify waybar appears: `systemctl --user status waybar.service`
