# Hyprland Session Service Ordering Hardening

## Goal

Make Hyprland session startup on `predator` deterministic: display-bound user services must start only after the compositor has exported the Wayland session environment to `systemd --user` and D-Bus, and they must stop/restart cleanly across session restarts. The result should be simple to reason about, easy to maintain, and not dependent on ad-hoc `exec-once` launches for individual services.

## Background

This plan follows the diagnosis saved in:

- `docs/for-agents/archive/reports/078-waybar-tray-startup-diagnosis-report.md`

That report identified the Waybar tray issue as a broader `systemd --user` ordering/session-environment problem, not a Waybar JSON/tray configuration problem.

## Scope

In scope:
- `predator` Hyprland session startup and display-bound user services.
- The `systemd --user` dependency graph for `graphical-session.target`, `hyprland-session.target`, `tray.target`, and display-bound services.
- Portal startup/restart behavior where it depends on session environment.
- Tracked Nix/Home Manager configuration and tracked mutable-config templates.
- One-time live cleanup commands needed to exit the current bad runtime state after the declarative fix is applied.

Out of scope:
- Changing desktop selection away from Hyprland.
- Replacing Home Manager or `systemd --user` as the service manager.
- Reworking visual Waybar CSS/JSON unrelated to startup ordering.
- GPU/performance/scheduler work already covered by plan 084.
- Reopening the `dbus-broker` vs `dbus-daemon` question; the evidence here points to ordering/environment, not broker implementation.

## Repo Philosophy and Ownership Check

This plan intentionally follows the repo's operating model:

- Keep the fix in existing narrow owners:
  - `modules/features/system/keyrs.nix` owns `keyrs` service semantics.
  - `modules/features/desktop/hyprland.nix` and/or `modules/desktops/hyprland-standalone.nix` own the Hyprland session entrypoint.
  - `modules/features/desktop/session-applets.nix`, `waybar.nix`, `waypaper.nix`, and `fcitx5.nix` own their respective user session services/drop-ins.
- Do **not** introduce a generic repo-local session framework, host carrier, role selector, or new broad option surface.
- Do **not** use `specialArgs` / `extraSpecialArgs` plumbing.
- Prefer small Home Manager/systemd drop-ins over full unit redefinitions.
- Keep host composition explicit in `modules/hosts/predator.nix`; only add imports there if a real new published module is introduced, which is not expected.
- Keep machine hardware policy out of this change; no changes under `hardware/` are planned.
- Do not read or reference untracked `private/users/*` or `private/hosts/*` files.
- Do not hardcode usernames in module code. Validation snippets use `<userName>` as a placeholder for the tracked Home Manager user wired by the host.
- Validate runtime behavior, not only Nix evaluation/builds.

Command convention in this plan:

```bash
userName='<tracked-home-manager-user>'
```

Use that shell variable for commands that need the concrete Home Manager user attr.

## Current State

### Repo facts

Relevant files:

- `modules/features/desktop/session-applets.nix`
- `modules/features/desktop/waybar.nix`
- `modules/features/desktop/waypaper.nix`
- `modules/features/desktop/fcitx5.nix`
- `modules/features/desktop/hyprland.nix`
- `modules/features/system/keyrs.nix`
- `modules/desktops/hyprland-standalone.nix`
- `config/desktops/hyprland-standalone/hyprland.conf`
- `config/apps/waybar/config`

Current Hyprland generated config in the live home:

```text
~/.config/hypr/hyprland.conf:
exec-once = dbus-update-activation-environment --systemd DISPLAY HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target
source = ~/.config/hypr/user.conf
```

Current mutable startup config still has a manual Waybar start:

```text
~/.config/hypr/startup.conf:
exec-once = systemctl --user reset-failed waybar.service ; systemctl --user start waybar.service
```

The tracked template `config/desktops/hyprland-standalone/hyprland.conf` also still contains a Waybar `exec-once` start. That keeps session orchestration split between declarative systemd targets and ad-hoc compositor config.

### Live system evidence

The current SSH session is not a graphical Hyprland session, but the live user manager still has graphical-session state active:

```text
systemctl --user --failed
- blueman-applet.service failed
- cliphist-images.service failed
- hyprpolkitagent.service failed
- network-manager-applet.service failed
- xdg-desktop-portal-gtk.service failed
```

Current unit states show:

```text
waybar.service                 inactive/dead because ConditionEnvironment=WAYLAND_DISPLAY was not met
tray.target                    active
udiskie.service                active/running, but it had started without tray integration
cliphist.service               repeatedly restarting without Wayland
wl-clip-persist.service        repeatedly restarting without Wayland
xdg-desktop-portal.service     active
xdg-desktop-portal-gtk.service failed/start-limit-hit
```

This is not only a graphical-session race after Hyprland starts. The user manager can enter graphical-session state even when no compositor is running.

### Smoking gun: `keyrs.service` pulls the graphical session from `default.target`

Live unit:

```ini
# /etc/systemd/user/keyrs.service
[Unit]
After=graphical-session.target
Wants=graphical-session.target

[Install]
WantedBy=default.target
```

Because `keyrs.service` is wanted by `default.target` and wants `graphical-session.target`, the user manager can start `graphical-session.target` during a normal user-manager startup, including non-graphical contexts such as SSH/linger. That immediately triggers all Home Manager services wanted by `graphical-session.target` before Wayland exists.

This explains the 22:29:12 boot/session log sequence:

```text
Reached target Current graphical user session.
Started swww wallpaper daemon (awww-daemon).
Started Clipboard management daemon - images.
Started Clipboard management daemon.
Started Fcitx5 input method editor.
hypridle skipped, unmet condition check ConditionEnvironment=WAYLAND_DISPLAY
Started Hyprland PolicyKit Agent.
Highly customizable Wayland bar ... skipped, unmet condition check ConditionEnvironment=WAYLAND_DISPLAY
Reached target Home Manager System Tray.
Started Blueman applet.
Started Network Manager applet.
Started udiskie mount daemon.
Started Wayland clipboard persistence daemon.
```

Then the display-bound failures follow:

```text
nm-applet: cannot open display:
blueman: gtk_icon_theme_get_for_screen: assertion 'GDK_IS_SCREEN (screen)' failed
udiskie: Not run within X or Wayland session. Starting udiskie without tray icon.
wl-paste: WAYLAND_DISPLAY is unset
wl-clip-persist: Failed to connect to wayland server
hyprpolkitagent: Failed to create wl_display
xdg-desktop-portal-gtk: cannot open display:
```

### Current target/service topology problems

1. `default.target` indirectly starts `graphical-session.target` through `keyrs.service`.
2. Display-bound services are mostly wanted by `graphical-session.target`, so a premature graphical target starts the entire desktop service set headlessly.
3. `tray.target` only expresses a target relationship; it does not prove Waybar is running or ready as a tray host.
4. Some services have `ConditionEnvironment=WAYLAND_DISPLAY` and skip; others crash, start without tray, or loop.
5. D-Bus-activatable services like portals can be activated before the compositor imports the correct environment, then persist with stale/no display environment unless explicitly restarted.
6. The mutable Hyprland startup config still manually starts `waybar.service`, duplicating and partially bypassing the systemd target graph.

## Execution Status

Implemented in the working tree:

- `modules/features/system/keyrs.nix`: `keyrs.service` no longer wants `graphical-session.target` from `default.target`; it is now bound to `graphical-session.target` and guarded by `ConditionEnvironment=WAYLAND_DISPLAY`.
- `modules/features/desktop/hyprland.nix`: Hyprland now uses a generated, readable `hyprland-session-start` helper through Home Manager's official Hyprland `systemd.extraCommands`; the helper clears stale session/portal state, imports session environment, resets failed units, and starts `hyprland-session.target`.
- `modules/features/desktop/session-applets.nix`: display-bound applets and clipboard services are guarded by `ConditionEnvironment=WAYLAND_DISPLAY`, have saner restart behavior, and tray applets are ordered after/Wants `waybar.service`.
- `modules/features/desktop/waybar.nix`: Waybar has explicit `ConditionEnvironment=WAYLAND_DISPLAY` and `RestartSec=2`.
- `modules/features/desktop/waypaper.nix`: `awww-daemon` is guarded by `ConditionEnvironment=WAYLAND_DISPLAY`.
- `modules/features/desktop/fcitx5.nix`: `fcitx5-daemon` is guarded by `ConditionEnvironment=WAYLAND_DISPLAY`.
- `modules/desktops/hyprland-standalone.nix`: GTK portal override is guarded by `ConditionEnvironment=WAYLAND_DISPLAY` and gets restart pacing.
- `config/desktops/hyprland-standalone/hyprland.conf`: the tracked template no longer manually starts `waybar.service`.
- Live mutable file `~/.config/hypr/startup.conf`: the manual Waybar start was removed once.
- Live stale user symlink `~/.config/systemd/user/default.target.wants/keyrs.service` was removed.

Validation completed:

- `nix eval` confirmed the new `keyrs.service` wanted/wants/after/partOf/ConditionEnvironment values.
- `nix eval` confirmed the Hyprland generated config imports `NIX_XDG_DESKTOP_PORTAL_DIR` and calls `hyprland-session-start`.
- `nix eval` confirmed the intended Home Manager unit snippets for Waybar, applets, clipboard, Fcitx, hyprpolkitagent, and awww.
- `nix build --no-link .#nixosConfigurations.predator.config.home-manager.users.<userName>.home.path` passed.
- `nix build --no-link .#nixosConfigurations.predator.config.system.build.toplevel` passed.
- `./scripts/run-validation-gates.sh structure` passed.

Blocked runtime application:

- `nh os switch path:$PWD --out-link "$PWD/result"` built successfully but activation failed because the SSH command cannot provide the required sudo password/TTY.
- The full declarative fix still needs a privileged switch from an interactive shell/TTY:

```bash
nh os switch path:$HOME/nixos --out-link "$HOME/nixos/result"
```

Runtime cleanup performed over SSH after the failed switch:

```bash
systemctl --user stop hyprland-session.target graphical-session.target tray.target || true
systemctl --user reset-failed || true
```

After cleanup, all affected user units were inactive/dead and `systemctl --user --failed` reported zero failed units. Final acceptance still requires logging into Hyprland after the privileged switch.

## Desired End State

### Simple mental model

There should be one clear contract:

1. `default.target` is non-graphical and must not start `graphical-session.target`.
2. Hyprland is the only thing that opens the graphical session.
3. Hyprland first exports its session environment to D-Bus and `systemd --user`.
4. Only after that, Hyprland starts the session target.
5. Display-bound user services are bound to the graphical/Hyprland session lifecycle and never start from SSH/linger/default user-manager startup.
6. Manual per-service `exec-once` starts in Hyprland config are removed unless the service truly cannot be modeled as a user unit.

### Runtime assertions

With no graphical login active:

```bash
systemctl --user is-active graphical-session.target hyprland-session.target tray.target
```

should not show those targets active just because SSH opened the user manager.

After entering Hyprland:

```bash
systemctl --user show-environment | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE'
systemctl --user is-active hyprland-session.target graphical-session.target tray.target waybar.service network-manager-applet.service blueman-applet.service udiskie.service fcitx5-daemon.service hyprpolkitagent.service
```

should show the session environment and active services.

Logs after login should not contain:

```text
cannot open display
WAYLAND_DISPLAY is unset
Not run within X or Wayland session
start-limit-hit
ConditionEnvironment=WAYLAND_DISPLAY was not met
Failed to create wl_display
```

for the session services being fixed.

## Proposed Architecture

### Session ownership contract

Use the existing Home Manager/Hyprland session mechanism instead of inventing a parallel framework:

- keep `hyprland-session.target` as the compositor-specific session anchor;
- let it bind to the standard `graphical-session.target` as Home Manager expects;
- ensure nothing from `default.target` starts `graphical-session.target`;
- make Hyprland's environment-import/start command the only supported entry point into the graphical target graph.

### Add a small declarative session entrypoint helper

Replace the opaque inline `exec-once` command with a small generated helper script owned by the Hyprland desktop composition or Hyprland feature. The helper should be readable and auditable.

Responsibilities:

1. stop stale session targets/services if they were accidentally left active;
2. reset failed display-bound units from previous failed attempts;
3. export session variables to both D-Bus activation and `systemd --user`;
4. restart portals that may have been D-Bus-activated too early with stale/no display environment;
5. start `hyprland-session.target`.

Candidate shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Clear stale or premature session state first.
systemctl --user stop hyprland-session.target graphical-session.target || true

# Make sure stale portal instances do not keep a pre-Hyprland environment.
systemctl --user stop \
  xdg-desktop-portal.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-hyprland.service || true

# Clear failed counters caused by earlier non-graphical user-manager startup.
systemctl --user reset-failed \
  waybar.service \
  network-manager-applet.service \
  blueman-applet.service \
  udiskie.service \
  cliphist.service \
  cliphist-images.service \
  wl-clip-persist.service \
  fcitx5-daemon.service \
  hyprpolkitagent.service \
  awww-daemon.service \
  xdg-desktop-portal.service \
  xdg-desktop-portal-gtk.service \
  xdg-desktop-portal-hyprland.service || true

# Import the compositor environment.
dbus-update-activation-environment --systemd \
  DISPLAY \
  WAYLAND_DISPLAY \
  HYPRLAND_INSTANCE_SIGNATURE \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_TYPE \
  NIX_XDG_DESKTOP_PORTAL_DIR

# Start the graphical session transaction after the environment is visible.
systemctl --user start hyprland-session.target
```

Notes:
- Validate whether `systemctl --user import-environment ...` is needed in addition to `dbus-update-activation-environment --systemd`. If `dbus-update-activation-environment --systemd` is proven sufficient, keep the helper minimal.
- Portal stop/restart is included because `xdg-desktop-portal.service` is D-Bus activatable and was observed active even when `xdg-desktop-portal-gtk.service` had failed headlessly.

### Service placement contract

For display-bound user services:

- `PartOf=graphical-session.target` or `PartOf=hyprland-session.target` so they stop with the session.
- `After=graphical-session.target`/`hyprland-session.target` so they do not race the target entry.
- `ConditionEnvironment=WAYLAND_DISPLAY` for services that cannot function without Wayland.
- `Restart=on-failure` plus sane `RestartSec` for applets that can crash during transient restarts.
- Avoid `WantedBy=default.target` for any display-bound service.

For tray applets:

- Keep `tray.target` as a grouping convenience only.
- Do not treat `tray.target` as proof that Waybar is ready.
- Prefer `After=waybar.service` and `Wants=waybar.service` for `nm-applet`, `blueman-applet`, and `udiskie` if runtime validation shows host-before-item ordering is still needed after the environment fix.

## Phases

### Phase 0: Baseline capture

Targets:
- Capture the broken state before changes so the fix can be proven.

Commands:

```bash
systemctl --user --failed --no-pager || true
systemctl --user list-units \
  'graphical-session.target' \
  'hyprland-session.target' \
  'tray.target' \
  'waybar.service' \
  'network-manager-applet.service' \
  'blueman-applet.service' \
  'udiskie.service' \
  'cliphist*.service' \
  'wl-clip-persist.service' \
  'hyprpolkitagent.service' \
  'awww-daemon.service' \
  'xdg-desktop-portal*.service' \
  --all --no-pager
systemctl --user cat keyrs.service waybar.service tray.target network-manager-applet.service blueman-applet.service udiskie.service --no-pager
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR' || true
journalctl --user -b --since '30 minutes ago' --no-pager | rg -i 'graphical-session|hyprland-session|tray.target|waybar|nm-applet|blueman|udiskie|cliphist|wl-clip|hyprpolkit|xdg-desktop-portal|cannot open display|WAYLAND_DISPLAY|start-limit-hit|wl_display' || true
```

Validation:
- Confirm `keyrs.service` is still the premature trigger before changing it.
- Confirm no assumptions are based on SSH environment pretending to be graphical.

Diff expectation:
- No repo changes.

Commit target:
- none.

### Phase 1: Remove the premature `default.target` -> graphical session edge

Targets:
- `modules/features/system/keyrs.nix`

Changes:
- Override the upstream `keyrs.service` user unit so it no longer pulls `graphical-session.target` from `default.target`.
- Desired unit semantics:
  - no `WantedBy=default.target`;
  - no `Wants=graphical-session.target` from a default-started service;
  - start only as part of the compositor/graphical session;
  - stop with the graphical session.

Candidate Nix shape to verify against the actual `services.keyrs` module/options:

```nix
systemd.user.services.keyrs = {
  wantedBy = lib.mkForce [ "graphical-session.target" ];
  wants = lib.mkForce [ ];
  after = lib.mkForce [ "graphical-session.target" ];
  partOf = [ "graphical-session.target" ];
  unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
};
```

If the external module uses different option names, first inspect/evaluate the generated unit and adapt with the smallest override that changes the generated unit to the desired topology.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.systemd.user.services.keyrs
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Post-switch runtime validation while **not** logged into Hyprland:

```bash
systemctl --user daemon-reload
systemctl --user reset-failed keyrs.service graphical-session.target || true
systemctl --user restart default.target || true
systemctl --user is-active graphical-session.target hyprland-session.target tray.target || true
systemctl --user --failed --no-pager || true
```

Expected:
- `default.target` no longer activates `graphical-session.target`.
- Display-bound services do not start/fail merely because the user manager is alive over SSH.

Diff expectation:
- The only evaluated unit graph change in this phase should be `keyrs.service` install/order/session binding.

Commit target:
- `fix(keyrs): stop pulling graphical session from default target`

### Phase 2: Create a readable Hyprland session entrypoint

Targets:
- `modules/features/desktop/hyprland.nix` or `modules/desktops/hyprland-standalone.nix`
- potentially a generated script package through `pkgs.writeShellScriptBin` or inline store path.

Changes:
- Replace the current generated/inline session bootstrap with a readable helper, or configure Home Manager's Hyprland integration to call the helper after its environment import point.
- The helper must be the single entry point that imports environment and starts `hyprland-session.target`.
- Include portal restart/reset in the helper because portals are D-Bus activatable and can be active with stale environment before Hyprland starts.

Implementation notes:
- First inspect Home Manager Hyprland options around `wayland.windowManager.hyprland.systemd.*` to avoid fighting generated config.
- Prefer an official HM option if it can call the helper cleanly.
- If the generated line cannot be reshaped safely, use a small extra `exec-once` before `source = ~/.config/hypr/user.conf` and disable the conflicting generated systemd integration only if validated.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.wayland.windowManager.hyprland
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.home.path
```

Runtime validation after switching and entering Hyprland:

```bash
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR'
systemctl --user is-active hyprland-session.target graphical-session.target
journalctl --user --since '5 minutes ago' --no-pager | rg -i 'session entrypoint|graphical-session|hyprland-session|cannot open display|WAYLAND_DISPLAY|start-limit-hit|xdg-desktop-portal' || true
```

Expected:
- The environment is present in the user manager after Hyprland starts.
- Stale portal services are not left running with pre-Hyprland env.
- `hyprland-session.target` starts after environment import.

Diff expectation:
- One readable helper or equivalent declarative command replaces opaque ad-hoc command composition.

Commit target:
- `fix(hyprland): centralize session environment startup`

### Phase 3: Remove ad-hoc Waybar startup from mutable/tracked Hyprland config

Targets:
- `config/desktops/hyprland-standalone/hyprland.conf`
- one-time live file: `~/.config/hypr/startup.conf`

Changes:
- Remove tracked template line:

```text
exec-once = systemctl --user reset-failed waybar.service ; systemctl --user start waybar.service
```

- Remove the same line from the live mutable `~/.config/hypr/startup.conf` after user approval/coordination.
- Keep Waybar owned by `programs.waybar.systemd.enable = true` and the session target graph.

Validation:

```bash
rg -n 'waybar.service|systemctl --user.*waybar' config/desktops ~/.config/hypr || true
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.home.path
```

Runtime validation:

```bash
systemctl --user reset-failed waybar.service
# log out/in to Hyprland
systemctl --user is-active waybar.service
journalctl --user -u waybar.service --since '5 minutes ago' --no-pager
```

Expected:
- Waybar starts from the session target graph, not from an individual Hyprland `exec-once`.

Diff expectation:
- Tracked mutable template no longer encourages service-level manual startup.
- Live mutable config is cleaned once, not repeatedly overwritten by activation.

Commit target:
- `fix(waybar): let systemd session own bar startup`

### Phase 4: Harden display-bound services under the session contract

Targets:
- `modules/features/desktop/session-applets.nix`
- `modules/features/desktop/waybar.nix`
- `modules/features/desktop/waypaper.nix`
- `modules/features/desktop/fcitx5.nix`
- `modules/features/desktop/hyprland.nix`
- `modules/desktops/hyprland-standalone.nix` for composition-level drop-ins if preferable.

Changes:
- Add a small, readable set of systemd user drop-ins so all known display-bound services share the same contract:
  - `ConditionEnvironment=WAYLAND_DISPLAY` where missing;
  - `PartOf=graphical-session.target` or `PartOf=hyprland-session.target`;
  - no `WantedBy=default.target`;
  - restart behavior only where failure is recoverable and useful.
- Apply to:
  - `waybar.service`
  - `network-manager-applet.service`
  - `blueman-applet.service`
  - `udiskie.service`
  - `cliphist.service`
  - `cliphist-images.service`
  - `wl-clip-persist.service`
  - `hyprpolkitagent.service`
  - `fcitx5-daemon.service`
  - `hypridle.service`
  - `awww-daemon.service`
  - `xdg-desktop-portal-gtk.service`
  - `xdg-desktop-portal-hyprland.service`

Potential service-specific notes:
- `nm-applet`, `blueman-applet`, and `udiskie` currently fail or degrade when started without display; give them `Restart=on-failure` and `RestartSec=2` if needed.
- `cliphist-images.service` currently lacks the `RestartSec=2` override that `cliphist.service` has; align it to avoid start-limit bursts.
- `awww-daemon.service` currently restarts and dumps core repeatedly without Wayland; guard with `ConditionEnvironment=WAYLAND_DISPLAY`.
- `xdg-desktop-portal-gtk.service` currently has no `ConditionEnvironment=WAYLAND_DISPLAY`; guard it and ensure the session entrypoint restarts/reset-failed it after environment import.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.systemd.user.services
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Runtime validation with no graphical session:

```bash
systemctl --user reset-failed
systemctl --user stop graphical-session.target hyprland-session.target tray.target || true
systemctl --user restart default.target || true
sleep 2
systemctl --user --failed --no-pager || true
journalctl --user --since '2 minutes ago' --no-pager | rg -i 'cannot open display|WAYLAND_DISPLAY is unset|wl_display|start-limit-hit|Not run within X or Wayland session' || true
```

Runtime validation inside Hyprland:

```bash
systemctl --user is-active \
  waybar.service \
  network-manager-applet.service \
  blueman-applet.service \
  udiskie.service \
  cliphist.service \
  wl-clip-persist.service \
  fcitx5-daemon.service \
  hyprpolkitagent.service \
  awww-daemon.service

journalctl --user --since '5 minutes ago' --no-pager | rg -i 'cannot open display|WAYLAND_DISPLAY is unset|wl_display|start-limit-hit|Not run within X or Wayland session' || true
```

Diff expectation:
- Small declarative drop-ins only; no copy-paste redefinition of full upstream units unless unavoidable.

Commit target:
- `fix(desktop): guard display services behind session environment`

### Phase 5: Portal-specific acceptance

Targets:
- `modules/desktops/hyprland-standalone.nix`
- `xdg-desktop-portal*` user units.

Changes:
- Ensure the previous portal completeness fix remains intact:
  - GTK backend available;
  - Hyprland backend available;
  - FileChooser/OpenURI/Settings present.
- Ensure portal services start/restart only with the correct user-manager environment.

Validation inside Hyprland:

```bash
systemctl --user show -p MainPID --value xdg-desktop-portal | xargs -r -I{} sh -c 'tr "\\0" "\\n" < /proc/{}/environ | rg "WAYLAND_DISPLAY|XDG_CURRENT_DESKTOP|NIX_XDG_DESKTOP_PORTAL_DIR"'
busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop | rg 'FileChooser|OpenURI|Settings|ScreenCast|Screenshot'
systemctl --user status xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-hyprland --no-pager
journalctl --user -u xdg-desktop-portal -u xdg-desktop-portal-gtk -u xdg-desktop-portal-hyprland --since '5 minutes ago' --no-pager
```

Expected:
- Portal main process has the Hyprland/Wayland environment.
- `FileChooser`, `OpenURI`, and `Settings` are exposed.
- No `cannot open display` or `start-limit-hit` on GTK portal.

Diff expectation:
- Portal changes stay in the Hyprland desktop composition or narrow portal/session owner, not scattered into unrelated features.

Commit target:
- can be folded into Phase 2/4 commit if the actual code is just the session-entrypoint portal restart.

### Phase 6: End-to-end acceptance and regression checks

Targets:
- Prove the problem is fixed in real behavior, not just builds.

No-Hyprland/SSH acceptance:

```bash
systemctl --user reset-failed
systemctl --user stop graphical-session.target hyprland-session.target tray.target || true
systemctl --user restart default.target || true
sleep 5
systemctl --user is-active graphical-session.target hyprland-session.target tray.target || true
systemctl --user --failed --no-pager || true
journalctl --user --since '5 minutes ago' --no-pager | rg -i 'cannot open display|WAYLAND_DISPLAY is unset|wl_display|start-limit-hit|Not run within X or Wayland session' || true
```

Expected:
- No display-bound services start or fail from SSH/default startup.

Hyprland login acceptance:

```bash
systemctl --user show-environment | sort | rg 'WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|HYPRLAND_INSTANCE_SIGNATURE|NIX_XDG_DESKTOP_PORTAL_DIR'
systemctl --user is-active hyprland-session.target graphical-session.target tray.target waybar.service network-manager-applet.service blueman-applet.service udiskie.service cliphist.service wl-clip-persist.service fcitx5-daemon.service hyprpolkitagent.service awww-daemon.service
journalctl --user --since '10 minutes ago' --no-pager | rg -i 'cannot open display|WAYLAND_DISPLAY is unset|wl_display|start-limit-hit|Not run within X or Wayland session' || true
```

Manual UI acceptance:
- Waybar appears once.
- Tray contains expected applets (`nm-applet`, `blueman`, `udiskie` when relevant).
- Clipboard history works.
- Fcitx works in Zed/Firefox.
- Polkit prompt appears when triggering an action requiring authentication.
- Wallpaper daemon works / waypaper button works.
- Zed file picker works through portal.

Restart acceptance:

```bash
systemctl --user restart waybar.service
systemctl --user restart network-manager-applet.service blueman-applet.service udiskie.service
systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gtk.service xdg-desktop-portal-hyprland.service
journalctl --user --since '2 minutes ago' --no-pager | rg -i 'cannot open display|WAYLAND_DISPLAY is unset|start-limit-hit' || true
```

Expected:
- Restarting components inside Hyprland does not recreate the race.

Validation gates:

```bash
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.home.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.${userName}.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
./scripts/check-repo-public-safety.sh
```

Diff/closure expectation:
- Only user-session unit topology, Hyprland startup script/config, and related service drop-ins should change.
- No private files.
- No unrelated package upgrades unless already present in `flake.lock` and explicitly handled separately.

Commit target:
- final fix commit only if earlier phases were not committed separately.

## Risks

- Changing login/session startup can break the graphical session if applied incorrectly. Keep changes small and preserve rollback via previous NixOS generation.
- `keyrs` may be needed early for keyboard remapping. Moving it behind graphical session should be validated with the actual login/session path. If key remapping is needed at greeter time, it may need a separate system-level greeter-owned path instead of a user default-target service that pulls the full graphical session.
- `ConditionEnvironment=WAYLAND_DISPLAY` prevents bad starts but does not by itself retry when environment later appears. The entrypoint must start/restart the session target after importing env.
- Portal services are D-Bus activatable; they can start outside the target graph. The session entrypoint must restart stale instances, not only set target ordering.
- Mutable Hyprland files can drift. Removing the tracked Waybar autostart template is not enough if the live `~/.config/hypr/startup.conf` still contains a manual start.
- `graphical-session.target` is a generic systemd target shared by other desktop integrations. Keep Hyprland-specific policy in the Hyprland desktop composition or clearly named feature.

## Rollback

If graphical login breaks:

1. Use TTY or SSH.
2. Switch to the previous NixOS generation:

```bash
sudo nixos-rebuild switch --rollback
```

or boot the previous generation from the bootloader.

3. Stop bad user-session state:

```bash
systemctl --user stop hyprland-session.target graphical-session.target tray.target || true
systemctl --user reset-failed || true
```

4. Restore the previous `~/.config/hypr/startup.conf` Waybar line only as a temporary workaround, not as the final architecture.

## Definition of Done

- `default.target` no longer starts or wants `graphical-session.target` through `keyrs` or any other display-bound service.
- Starting an SSH/user-manager session with no Hyprland does not start/fail Waybar, tray applets, portals, clipboard, Fcitx, hyprpolkitagent, or awww.
- Entering Hyprland imports the Wayland environment into `systemd --user` and D-Bus before display-bound services start.
- Waybar and tray applets start consistently without manual `exec-once` service starts.
- Portal services expose `FileChooser`, `OpenURI`, and `Settings` and have the correct session environment.
- No repeated `cannot open display`, `WAYLAND_DISPLAY is unset`, or `start-limit-hit` messages in the user journal after login.
- Nix eval/build and repo safety gates pass.
- The final architecture is documented in the relevant module comments or this plan is updated with the exact implementation notes before being archived.
