# Hyprland portal backend completeness (FileChooser/OpenURI)

## Goal

Ensure the Hyprland user session always exposes the complete XDG Desktop Portal interface set required by apps like Zed (especially FileChooser, OpenURI, and Settings), with a declarative fix that survives login/reboot.

## Scope

In scope:
- Fix Home Manager portal backend composition for Predator Hyprland session
- Ensure `NIX_XDG_DESKTOP_PORTAL_DIR` points to a merged portal set that includes GTK backend definitions
- Validate portal interfaces at runtime (`org.freedesktop.portal.FileChooser`, `OpenURI`, `Settings`)

Out of scope:
- Replacing Hyprland portal backend
- Reworking dbus implementation (`broker` vs `dbus`)
- Desktop-agnostic refactors for all hosts

## Current State

- Runtime failure observed in Zed: missing xdg-desktop-portal implementation for file picker.
- `xdg-desktop-portal` currently receives `NIX_XDG_DESKTOP_PORTAL_DIR` from HM session vars.
- That HM portal dir can contain only `hyprland.portal`, missing `gtk.portal`, so FileChooser/OpenURI/Settings vanish.
- NixOS-level portal config is correct (`default=hyprland;gtk`), but effective runtime backend list is constrained by HM-provided portal directory.

## Desired End State

- HM merged portal directory for Predator Hyprland includes at least:
  - `hyprland.portal`
  - `gtk.portal`
- `org.freedesktop.portal.Desktop` exposes:
  - `FileChooser`
  - `OpenURI`
  - `Settings`
  - (plus existing `ScreenCast`/`Screenshot`)
- Zed file picker and link opening work consistently after reboot.

## Phases

### Phase 1: Add GTK backend to HM portal composition

Targets:
- `modules/desktops/hyprland-standalone.nix`

Changes:
- Extend the HM owner to explicitly configure `xdg.portal` in user space:
  - include `pkgs.xdg-desktop-portal-gtk` in `extraPortals`
  - keep Hyprland backend selected for screencast/screenshot
  - keep GTK selected for FileChooser/OpenURI/Settings
- Keep existing PATH overrides for portal units.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.portal.extraPortals`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.portal.config`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- HM portal merged dir now includes both hyprland and gtk portal descriptors.

Commit target:
- `fix(portal): include gtk backend in hyprland HM portal composition`

### Phase 2: Runtime confirmation on Predator session

Targets:
- runtime only (no file edits)

Changes:
- `nh os switch` (or equivalent)
- relogin/reboot to refresh user manager env
- verify portal service environment and exposed interfaces

Validation:
- `systemctl --user show xdg-desktop-portal -p Environment`
- `busctl --user introspect org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop`
- confirm interfaces present:
  - `org.freedesktop.portal.FileChooser`
  - `org.freedesktop.portal.OpenURI`
  - `org.freedesktop.portal.Settings`
- manual test:
  - Zed: open file picker
  - click link from app/browser with portal path

Diff expectation:
- no more “missing xdg-desktop-portal implementation” in Zed for file picker.

Commit target:
- none (runtime verification)

## Risks

- HM/NixOS dual ownership of `xdg.portal` can create accidental drift if both set incompatible defaults.
- If user session env keeps stale `NIX_XDG_DESKTOP_PORTAL_DIR`, runtime may still need full relogin/reboot.

## Definition of Done

- HM portal merged directory includes GTK and Hyprland backends.
- `org.freedesktop.portal.Desktop` exposes FileChooser/OpenURI/Settings at runtime.
- Zed file picker works without transient env workaround.
- `./scripts/run-validation-gates.sh structure` passes.
