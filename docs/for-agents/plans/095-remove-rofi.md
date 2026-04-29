# Plan 095: Remove Rofi from NixOS Repo

**Status:** planning
**Date:** 2026-04-29

## Context

Walker/Elephant now handles all launcher, clipboard, and powermenu flows. Rofi is no longer invoked by any keybind or Waybar button. The live config `~/.config/rofi/` (15 MB, 200 files from adi1090x collection) remains on disk but is unused.

## Scope

Remove Rofi from the **repo** (Nix modules, config, docs, theme). Live `~/.config/rofi/` cleanup is optional/housekeeping.

## Steps

### 1. Remove `modules/features/desktop/rofi.nix`

- Delete the file.

### 2. Remove `homeManager.rofi` from `modules/hosts/predator.nix`

- Remove the import line.

### 3. Remove `catppuccin.rofi.enable` from `modules/features/desktop/theme-base.nix`

- Remove `catppuccin.rofi.enable = true;` (line 40).

### 4. Remove `rofi-blur` layer rule from `config/desktops/hyprland-standalone/modules/rules.lua`

- Remove the `lr({ name = "rofi-blur", ... })` entry.

### 5. Update `docs/for-agents/001-repo-map.md`

- Remove `desktop/rofi.nix` entry from the feature modules list.
- Remove any rofi-specific references in descriptions.

### 6. Validate

```bash
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

### 7. Commit

```
chore(desktop): remove Rofi launcher

Replaced by Walker/Elephant stack. All launcher, clipboard, and
powermenu flows use Walker. Removes rofi module, catppuccin rofi
theming, rofi-blur layer rule, and host import.
```

## Out of Scope

- Live `~/.config/rofi/` directory cleanup (user housekeeping).
- aurelius/cerebelo hosts (they don't import rofi).

## Risk

- Low. No keybind or Waybar button references Rofi. `rofi` package remains in nixpkgs if ever needed again.
