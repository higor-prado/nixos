# Disable fcitx5 clipboard addon

## Goal

Disable the built-in clipboard addon in fcitx5 so that clipboard management is handled exclusively by the dedicated `cliphist` + `wl-clip-persist` stack, eliminating redundancy and avoiding two separate clipboard histories.

## Scope

In scope:
- Disable the fcitx5 clipboard addon via NixOS/Home Manager declarative config
- Validate that fcitx5 starts without the clipboard addon loaded
- Validate that `cliphist` + `wl-clip-persist` remain unaffected

Out of scope:
- Changes to `cliphist` or `wl-clip-persist` configuration
- Changes to other fcitx5 addons (waylandim, dbus, classicui, keyboard, etc.)
- Any mutable runtime config changes beyond what HM manages

## Current State

- `modules/features/desktop/fcitx5.nix` owns fcitx5 configuration (NixOS + HM)
- fcitx5 loads the `clipboard` addon by default (it is included in the base package)
- `cliphist` + `wl-clip-persist` are already configured in `modules/features/desktop/session-applets.nix`
- No explicit fcitx5 addon blacklist exists — all default addons load automatically
- HM fcitx5 settings only configure `classicui` theme via catppuccin
- User does not use CJK input methods, so the clipboard-as-candidate workflow has no value

## Desired End State

- fcitx5 starts without the `clipboard` addon loaded
- `cliphist` + `wl-clip-persist` remain the sole clipboard management stack
- No regression in fcitx5 input method functionality (keyboard, waylandim, dbus, classicui)

## Phases

### Phase 1: Disable fcitx5 clipboard addon

Targets:
- `modules/features/desktop/fcitx5.nix`

Changes:
- Add `fcitx5.addons = with pkgs; [ fcitx5-gtk ];` to the existing NixOS module if not already present (it already is).
- In the HM module, add the `clipboard` addon to the disabled list via fcitx5 settings:
  ```nix
  fcitx5.settings.addons = {
    clipboard = {
      globalSection = {
        "Enabled" = "False";
      };
    };
  };
  ```
  This writes to `~/.config/fcitx5/conf/clipboard.conf` declaratively via HM, disabling the addon without removing the package.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.i18n.inputMethod.fcitx5.settings.addons` should contain the clipboard disable entry
- `./scripts/run-validation-gates.sh structure`
- After switch: `journalctl --user -u fcitx5-daemon -n 30` should NOT show `Loaded addon clipboard`
- After switch: `cliphist` and `wl-clip-persist` still active: `systemctl --user status cliphist wl-clip-persist`

Diff expectation:
- fcitx5 starts with one fewer addon loaded (clipboard missing from log)
- No behavioral change to cliphist/wl-clip-persist

Commit target:
- `fix(fcitx5): disable built-in clipboard addon in favor of cliphist`

## Risks

- The fcitx5 HM module may not support `settings.addons` the same way as `globalOptions`/`inputMethod` — needs eval verification. If the path doesn't exist, the fallback is writing `xdg.configFile."fcitx5/conf/clipboard.conf"` directly.
- If the user has muscle memory of `Ctrl+;` for clipboard history, that shortcut will stop working inside fcitx5 (but `cliphist` via rofi covers the same need).

## Definition of Done

- `journalctl --user -u fcitx5-daemon` no longer contains `Loaded addon clipboard`
- `cliphist` and `wl-clip-persist` remain `active (running)`
- `./scripts/run-validation-gates.sh structure` passes
- Mandatory Nix validation gates pass:
  - `nix flake metadata`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
