# Predator GDM Monitor Layout Fix (COMPLETED 2026-05-09)

## Goal

Make the GDM greeter on `predator` open on `HDMI-A-1` (Samsung QN90D) instead of the disabled laptop panel, using Mutter/GDM's own monitor configuration path and a validation path that proves the evaluated NixOS system contains the intended layout before runtime testing.

## Scope

In scope:

- `predator` GDM greeter monitor selection.
- Declarative monitor layout for Mutter/GDM, separate from the Hyprland post-login layout.
- Static/eval/build checks plus a controlled runtime smoke test.

Out of scope:

- Changing Hyprland's existing monitor behavior after login.
- Replacing GDM or UWSM.
- Changing NVIDIA driver policy.
- Editing private overrides.

## Current State

- `modules/features/desktop/gdm.nix` enables GDM, sets `services.displayManager.defaultSession = "hyprland-uwsm"`, and force-limits `services.displayManager.sessionPackages` to the single UWSM session.
- `modules/hosts/predator.nix` imports `nixos.gdm`, `nixos.hyprland`, and `nixos.desktop-hyprland-standalone` only for `predator`.
- `config/desktops/hyprland-standalone/modules/monitors.lua` disables `eDP-1` and enables `HDMI-A-1` at `3840x2160@144`, scale `1.5`. This affects Hyprland after login, not GDM's greeter.
- Live Hyprland reports:
  - Hyprland reports active target: `HDMI-A-1`, vendor `Samsung Electric Company`, product `QN90D`, serial `0x01000E00`, mode `3840x2160@143.98801`, scale `1.50`.
  - Hyprland reports disabled panel: `eDP-1`, vendor `Chimei Innolux Corporation`, product `0x1616`, empty serial, available modes `1920x1200@165.00` and `1920x1200@60.01`.
  - Mutter does **not** use the Hyprland display strings verbatim. Mutter 49's `meta-output.c` sets monitor specs from EDID as manufacturer code/product-name-or-code/serial-string-or-code. For this hardware, `edid-decode` shows the Mutter specs must be `HDMI-A-1`/`SAM`/`QN90D`/`0x01000e00` and `eDP-1`/`CMN`/`0x1616`/`0x00000000`.
- `$HOME/.config/monitors.xml` is absent, `/etc/xdg/monitors.xml` is absent, and `/run/gdm/seat0/config/monitors.xml` is absent in the inspected runtime. So Mutter/GDM has no declarative monitor layout to apply at the greeter.
- Nixpkgs GDM is `gdm-49.2`; upstream GDM 49 source sets greeter `XDG_CONFIG_HOME` to `GDM_WORKING_DIR/<seat>/config` for seat sessions.
- Nixpkgs Mutter is `mutter-49.4`; `meta-monitor-config-store.c` reads system monitor configs from each `XDG_CONFIG_DIRS` entry as `monitors.xml`, then reads `g_get_user_config_dir()/monitors.xml`. Mutter's test fixture `policy.xml` proves system configs support:
  ```xml
  <policy>
    <stores>
      <store>system</store>
    </stores>
  </policy>
  ```
  which makes the system store authoritative instead of a user config overriding it.

## Desired End State

- `predator` evaluates to an `/etc/xdg/monitors.xml` payload for GDM/Mutter.
- The payload uses Mutter monitor XML version 2 with:
  - a system-only policy (`<store>system</store>`) so stale greeter/user monitor state cannot override the declared greeter layout;
  - one primary logical monitor on `HDMI-A-1` at the conservative EDID base mode `3840x2160@60`, scale `1`;
  - exact Mutter monitor spec `HDMI-A-1`/`SAM`/`QN90D`/`0x01000e00`;
  - `eDP-1` explicitly listed under `<disabled>` with exact Mutter spec `eDP-1`/`CMN`/`0x1616`/`0x00000000`.
- Hyprland's Lua monitor configuration remains unchanged.
- Servers (`aurelius`, `cerebelo`) do not get `/etc/xdg/monitors.xml` or any GDM setting.

## Phases

### Phase 0: Baseline and rollback

Targets:

- Confirm current evaluated GDM/UWSM state and current monitor identifiers.
- Keep a rollback path before any login/display-manager test.

Commands:

- `git status --short`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.services.displayManager.gdm.enable`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.services.displayManager.defaultSession`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.services.displayManager.sessionPackages`
- `hyprctl monitors all -j`
- `test ! -e /etc/xdg/monitors.xml || sed -n '1,220p' /etc/xdg/monitors.xml`
- `find /run/gdm -maxdepth 4 -type f -o -type d | sort`

Rollback:

- Do not restart `display-manager.service` until an SSH/TTY fallback is available.
- If greeter breaks, boot/select previous NixOS generation or run `sudo nixos-rebuild switch --rollback` from TTY.

### Phase 1: Add declarative Mutter monitor payload

Targets:

- New tracked XML payload, proposed path: `config/desktops/gdm/predator-monitors.xml`.
- `modules/hosts/predator.nix` wires that payload to `environment.etc."xdg/monitors.xml".source`.

Changes:

- Add a host-specific GDM/Mutter monitor XML using system-only policy and EDID-derived Mutter monitor specs, not Hyprland's human-readable display strings.
- Keep the wiring in the `predator` host owner because the EDID layout is host/display specific.
- Do not modify `hardware/predator/*` unless later evidence shows a DRM connector-level quirk is required.

Validation:

- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.environment.etc."xdg/monitors.xml".source`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.environment.etc | jq 'has("xdg/monitors.xml")'` must be `false`.
- `nix eval --json path:$PWD#nixosConfigurations.cerebelo.config.environment.etc | jq 'has("xdg/monitors.xml")'` must be `false`.
- XML parse check with `xmllint --noout config/desktops/gdm/predator-monitors.xml` if `xmllint` is available; otherwise Python `xml.etree.ElementTree`.

Diff expectation:

- Predator system closure changes only by adding one `/etc/xdg/monitors.xml` text payload; no session package or GDM/UWSM session drift.

Commit target:

- `fix(gdm): pin predator greeter monitor layout`

### Phase 2: Add non-regression contract

Targets:

- `scripts/check-config-contracts.sh`.

Changes:

- Add evaluated assertions that:
  - predator has `environment.etc."xdg/monitors.xml"`;
  - the source path exists in the working tree/store during `path:$PWD` eval;
  - `aurelius` and `cerebelo` do not have that file;
  - predator still has exactly one display-manager session package and default session remains `hyprland-uwsm`.
- Add a small XML content assertion in the script or a helper under `tests/scripts/` only if it does not require adding a new top-level gate category.

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`

Diff expectation:

- Contract changes are static/eval-only; no runtime behavior beyond Phase 1 payload.

Commit target:

- Same commit as Phase 1 unless the test change becomes large.

### Phase 3: Runtime smoke on predator

Targets:

- Prove GDM/Mutter reads the new layout and greeter appears on `HDMI-A-1`.

Preconditions:

- SSH or TTY fallback is available.
- Work is saved because restarting the display manager terminates the graphical session.

Commands:

- Build/test generation first: `nh os test path:$PWD --out-link "$HOME/.cache/nh-result-predator-gdm-monitor"`.
- Verify deployed file: `sed -n '1,220p' /etc/xdg/monitors.xml`.
- Restart or reboot into the tested generation.
- Inspect logs after greeter starts: `journalctl -u display-manager.service -b --no-pager | grep -Ei 'monitors config|monitors.xml|Failed to read'`.
- Human-visible acceptance: the GDM login prompt is on `HDMI-A-1`; laptop panel remains off/unused at greeter.

If it fails:

- Capture `journalctl -u display-manager.service -b --no-pager`.
- Capture live connector names from the greeter environment if accessible, otherwise temporarily run a GNOME session only to generate a fresh Mutter `monitors.xml`, compare connector/vendor/product/serial names, then fold the exact differences back into the tracked XML.
- Roll back before further iteration.

## Risks

- Mutter connector names may differ from Hyprland names on NVIDIA (`HDMI-A-1` vs another Mutter/KMS name). Runtime proof is required before claiming done.
- Mutter monitor specs use EDID manufacturer code/product/serial, not Hyprland's display description. Using Hyprland strings makes the XML fail to match.
- Mutter may reject fractional scale in GDM unless matching experimental settings are globally enabled, so the greeter layout intentionally uses scale `1`; Hyprland remains at `1.5` post-login.
- Monitor EDID serial/product data in tracked XML is host-specific. If this is considered private, move only the XML source to a private override and keep a tracked example/contract instead.
- Restarting GDM kills the current graphical session; test only with rollback access.

## Definition of Done

- `config/desktops/gdm/predator-monitors.xml` exists and parses as XML.
- `predator` evaluates `/etc/xdg/monitors.xml`; server hosts do not.
- `services.displayManager.defaultSession` remains `hyprland-uwsm` and GDM still exposes only the intended UWSM session package.
- `./scripts/run-validation-gates.sh structure` and `./scripts/run-validation-gates.sh predator` pass, or any failure is surfaced under Rule 999 before proceeding.
- Runtime smoke confirms the GDM greeter opens on `HDMI-A-1` with no Mutter monitor-config parse errors in the display-manager journal.
