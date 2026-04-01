# Predator Input Method and Steam Plan

## Goal

Make `predator` input-method behavior deterministic, modern, and easy to
reason about:
- `ç` / `Ç` should work consistently in the normal desktop apps and in Steam
- Wayland-native apps should keep the current modern `fcitx5` path
- X11/XWayland holdouts should get only the compatibility bridge they still need
- ownership should stay narrow and aligned with repo structure

The target is not "add more random IM exports until Steam works". The target is
to leave one clean, explainable stack:
- keyboard/layout facts in the keyboard owner
- IM session/runtime in the `fcitx5` owner
- GTK toolkit defaults in the GTK/theme owner
- Steam-specific compatibility in the gaming owner

## Scope

In scope:
- `predator` desktop input-method behavior
- `keyboard`, `fcitx5`, GTK settings, and Steam integration
- cleanup of duplicate `fcitx5` startup paths
- narrow XWayland compatibility for legacy apps, especially Steam
- runtime validation steps for both Wayland-native apps and Steam

Out of scope:
- redesigning the entire locale policy for the repo
- changing tracked keyboard layout away from `us/alt-intl`
- broad global exports that regress Wayland-native apps just to satisfy one app
- non-`predator` hosts unless a shared owner change genuinely benefits them
- unrelated Steam issues outside text input / cedilha

## Current State

- Keyboard layout ownership is already coherent:
  - NixOS XKB layout is set in
    [modules/features/system/keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
  - Niri uses the same `us` + `alt-intl` combination in
    [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
  - Fcitx5 profile also points at `keyboard-us-alt-intl` via
    [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)

- Cedilha fallback is currently handled by:
  - [modules/features/system/keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
    writing `~/.XCompose`

- Fcitx5 owner currently:
  - enables `i18n.inputMethod.type = "fcitx5"`
  - adds `pkgs.fcitx5-gtk`
  - writes the `xdg/fcitx5/profile`
  - does **not** explicitly manage GTK/XWayland compatibility files or
    session-level legacy bridge variables

- GTK settings are owned by:
  - [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)
  - current generated GTK config contains theme/cursor/font, but no
    `gtk-im-module=fcitx` fallback

- Fcitx5 startup is currently duplicated:
  - compositor startup in
    [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
  - Home Manager/systemd user service generated as
    [fcitx5-daemon.service](/home/higorprado/.config/systemd/user/fcitx5-daemon.service)

- Runtime evidence from the current session:
  - `fcitx5-daemon.service` is active
  - journal shows `Using Wayland native input method protocol: 1`
  - `GTK_IM_MODULE` and `QT_IM_MODULE` are intentionally empty in the `fcitx5`
    process
  - session environment currently lacks `XMODIFIERS`

- Steam owner state:
  - Steam is enabled in
    [modules/features/desktop/gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
  - no Steam-specific IM environment is configured
  - effective `programs.steam.extraPackages` currently contain fonts but no
    extra IM integration payload for Steam runtime

## Desired End State

- there is exactly one supported startup path for `fcitx5`
- Wayland-native apps keep using the Wayland-native frontend by default
- `XMODIFIERS` exists where needed for X11/XWayland apps
- GTK fallback for legacy/XWayland apps is explicit and owned in the right place
- Steam gets a narrow compatibility layer from the gaming owner instead of
  forcing legacy variables on the whole desktop
- `ç` works in:
  - a normal Wayland-native text field
  - a GTK/XWayland text field
  - Steam client text entry
- the resulting setup is easy to audit from the repo

## Main Technical Decisions

### 1. Preserve Wayland-native defaults

Do **not** globally force `GTK_IM_MODULE=fcitx` or `QT_IM_MODULE=fcitx` for the
whole session unless runtime proof shows it is unavoidable.

Reason:
- current session is already using Wayland-native IM correctly
- Fcitx upstream recommends avoiding global `GTK_IM_MODULE` in a modern Wayland
  setup when native frontend works
- broad legacy exports risk regressing popup behavior and native Wayland apps

### 2. Add only the legacy bridge that is still required

For X11/XWayland coverage:
- add `XMODIFIERS=@im=fcitx` from the `fcitx5` owner
- add GTK fallback through GTK configuration files owned by the GTK/theme owner
- only add Steam-specific `GTK_IM_MODULE` / `SDL_IM_MODULE` / related env inside
  the Steam owner if Steam still requires them

### 3. Keep ownership narrow

- `keyboard.nix` owns layout and compose semantics
- `fcitx5.nix` owns input-method runtime/session bridge
- `theme-base.nix` owns GTK-generated settings files
- `gaming.nix` owns Steam-specific behavior

Do not move Steam compatibility into hardware or host-local ad hoc exports.

## Phases

### Phase 0: Freeze Baseline and Reproduce Steam Failure

Targets:
- runtime only
- this plan

Changes:
- capture the exact Steam failure surface:
  - login field
  - chat
  - library search
  - game launch option fields
- confirm whether Steam and `steamwebhelper` are running via XWayland or
  native Wayland
- inspect `/proc/<pid>/environ` for `steam` and `steamwebhelper`
- record whether `~/.XCompose` is visible to the Steam process

Validation:
- `systemctl --user status fcitx5-daemon.service --no-pager`
- `journalctl --user -u fcitx5-daemon.service -b --no-pager | tail -n 120`
- `pgrep -a -f 'steam|steamwebhelper'`
- `xargs -0 -L1 -a /proc/<steam-pid>/environ | rg '^(GTK_IM_MODULE|QT_IM_MODULE|XMODIFIERS|SDL_IM_MODULE|XCOMPOSEFILE|WAYLAND_DISPLAY|DISPLAY)='`
- `xargs -0 -L1 -a /proc/<steamwebhelper-pid>/environ | rg '^(GTK_IM_MODULE|QT_IM_MODULE|XMODIFIERS|SDL_IM_MODULE|XCOMPOSEFILE|WAYLAND_DISPLAY|DISPLAY)='`

Diff expectation:
- no repo diff

Commit target:
- none

### Phase 1: Normalize Fcitx5 Startup Ownership

Targets:
- [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
- [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)

Changes:
- remove compositor-level `spawn-at-startup "fcitx5" "-d"`
- rely on the generated `fcitx5-daemon.service` as the only supported startup
  path
- keep the IM owner responsible for lifecycle instead of the compositor overlay

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `systemctl --user daemon-reload`
- fresh login
- `systemctl --user status fcitx5-daemon.service --no-pager`
- `pgrep -a fcitx5`

Diff expectation:
- exactly one `fcitx5` process after login
- no change to keyboard layout semantics yet

Commit target:
- `refactor(input): use a single fcitx startup path`

### Phase 2: Add Explicit XWayland Compatibility Without Polluting Wayland

Targets:
- [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)
- [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)

Changes:
- add `XMODIFIERS=@im=fcitx` from the `fcitx5` owner for X11/XWayland coverage
- keep global `GTK_IM_MODULE` and `QT_IM_MODULE` unset for the general Wayland
  session
- extend the GTK owner so generated GTK2/3/4 settings carry `fcitx` fallback
  for apps that still use GTK IM modules under X11/XWayland
- keep `.XCompose` in the keyboard owner unless runtime proof shows that
  another owner is more correct

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix store diff-closures /run/current-system ./result`
- fresh login
- `systemctl --user show-environment | rg '^XMODIFIERS='`
- `journalctl --user -u fcitx5-daemon.service -b --no-pager | tail -n 120`
- verify cedilha in:
  - kitty
  - Firefox/Brave
  - one GTK text field

Diff expectation:
- no regression in Wayland-native input
- XWayland/X11 apps now have an explicit bridge path

Commit target:
- `fix(input): add explicit xwayland input-method bridge`

### Phase 3: Add Narrow Steam Compatibility in the Gaming Owner

Targets:
- [modules/features/desktop/gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)

Changes:
- override `programs.steam.package` with Steam-specific IM environment only
  if Phase 2 does not already fix the issue
- preferred first-pass variables:
  - `XMODIFIERS=@im=fcitx`
  - `GTK_IM_MODULE=fcitx`
  - `SDL_IM_MODULE=fcitx`
  - `XCOMPOSEFILE=$HOME/.XCompose`
- add `pkgs.fcitx5-gtk` to `programs.steam.extraPackages` if runtime proof shows
  Steam needs the GTK module inside its own runtime
- do **not** broaden this to global desktop session variables

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix store diff-closures /run/current-system ./result`
- launch Steam from a fresh session
- inspect `steam` and `steamwebhelper` env again via `/proc/<pid>/environ`
- verify cedilha in the same Steam field(s) captured in Phase 0

Diff expectation:
- Steam receives compatibility env
- non-Steam desktop apps stay on the cleaner session defaults

Commit target:
- `fix(gaming): add steam input-method compatibility`

### Phase 4: Conditional Escalation if Steam Still Fails

Targets:
- likely still
  [modules/features/desktop/gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
- only widen scope if runtime evidence demands it

Changes:
- if Steam still drops input after Phase 3, determine the real missing piece:
  - child process env not propagating
  - runtime missing `fcitx5-gtk`
  - Chromium/CEF path requiring a different launch flag or env
- add the smallest Steam-only fix that matches the observed failure
- do not broaden to desktop-global exports unless Steam cannot be isolated

Validation:
- same runtime checks as Phase 3
- compare Phase 0 vs current Steam process environment

Diff expectation:
- only Steam-specific delta grows
- no repo-wide IM policy change unless proven necessary

Commit target:
- `fix(gaming): complete steam text-input fallback`

### Phase 5: Final Proof and Rollback Notes

Targets:
- active plan and/or accompanying active log if work execution starts

Changes:
- record the final chosen behavior:
  - which variables remain global
  - which variables are Steam-only
  - where GTK fallback is owned
  - how to verify after rebuild/login
- capture rollback path:
  - revert Steam-only override first
  - then revert GTK/XWayland bridge if needed

Validation:
- real desktop proof after rebuild/login:
  - kitty
  - Firefox/Brave
  - one GTK app
  - Steam client
- `./scripts/check-docs-drift.sh` if additional docs/logs are added

Diff expectation:
- clear operational story from tracked code

Commit target:
- `docs(input): record steam and fcitx runtime verification`

## Risks

1. Global legacy exports can regress Wayland-native apps.
   Mitigation:
   - keep `GTK_IM_MODULE` / `QT_IM_MODULE` unset globally unless proven necessary
   - prefer Steam-only env overrides

2. GTK fallback may fight with theme ownership.
   Mitigation:
   - make GTK changes in `theme-base.nix`, which already owns generated GTK
     settings

3. Steam may ignore host env or partially sandbox child processes.
   Mitigation:
   - inspect `/proc/<pid>/environ` for both `steam` and `steamwebhelper`
   - add `extraPackages` only if runtime proof requires it

4. Startup cleanup can temporarily remove IM from the session.
   Mitigation:
   - change startup in a small slice
   - verify `fcitx5-daemon.service` immediately after login

5. `.XCompose` may not be sufficient for every toolkit.
   Mitigation:
   - treat it as keyboard fallback, not as the only IM integration layer

## Definition of Done

- `fcitx5` has a single supported startup path
- layout ownership remains coherent across keyboard, Niri, and Fcitx5
- Wayland-native apps still work with the current modern frontend
- XWayland apps have an explicit compatibility bridge
- Steam text entry accepts `ç` without requiring broad desktop-global hacks
- ownership is auditable:
  - keyboard in `keyboard.nix`
  - IM runtime in `fcitx5.nix`
  - GTK fallback in `theme-base.nix`
  - Steam compatibility in `gaming.nix`
- validation and rollback steps are written down and reproducible
