# Report 096: Comprehensive Repo Audit

**Date:** 2026-04-29
**Scope:** modules/, config/, docs/for-agents/ (non-archive), flake.nix
**Branch:** cleanup/hyprland-only

## 1. Live ↔ Repo Drift (CRITICAL)

### 1a. `appearance.lua` — hyprlock overlay color alpha

| File | Value |
|------|-------|
| Live `~/.config/hypr/modules/appearance.lua` | `0xddb4befe` (87% opacity) |
| Repo `config/desktops/hyprland-standalone/modules/appearance.lua` | `0xffb4befe` (100% opacity) |

Hyprlock overlay at full opacity blocks visibility entirely. Live has the correct
semi-transparent value. Move live → repo.

### 1b. `input.lua` — `follow_mouse` value

| File | Value |
|------|-------|
| Live | `follow_mouse = 2` |
| Repo | `follow_mouse = 1` |

User explicitly changed this to reduce scroll-layout churn when moving mouse over
Waybar. Move live → repo.

### 1c. `rules.lua` — Waybar blur `ignore_alpha`

| File | Value |
|------|-------|
| Live | `ignore_alpha = 0.39` |
| Repo | `ignore_alpha = 0.49` |

Minor numeric drift. Move live → repo.

### 1d. `layout.lua` — trailing whitespace

| File | Diff |
|------|------|
| Live | blank line after line 11 |
| Repo | no blank line |

Trivial whitespace, but live wins by convention.

### 1e. `waybar/config` — `group/audio` vs `group/audiogroup`

| File | Value |
|------|-------|
| Live | `"group/audiogroup"` (modules-center) |
| Repo | `"group/audio"` (modules-center) |

The live CSS file references `#audiogroup` (not `#audio`). The repo style.css
targets `#audio` but uses `#audiogroup` in one place. These need to be
consistent. Move live → repo.

Additional diffs: `max-length` (36 vs 40), `format` (volume spacing),
trailing `align: 0`.

### 1f. `waybar/style.css` — dead CSS blocks

Repo has selectors the live version doesn't:

```css
/*#custom-powermenu,*/       /* commented out — dead */
#hardware > widget { ... }   /* doesn't exist in live */
#hardware > widget:first-child { ... }
#hardware > widget:last-child { ... }
```

Live has selectors the repo doesn't:

```css
#mpris,
#pulseaudio {
    min-width: 56px;
}
```

Move live → repo.

---

## 2. Zombie Code

### 2a. `startup.lua` — `hypr-dock` (BROKEN)

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("hypr-dock")
end)
```

The binary `hypr-dock` does not exist (`which hypr-dock` → NOT FOUND).
nwg-dock-hyprland was removed in commit `3546623`. This is a silent no-op that
runs a failing shell command on every compositor start.

**Fix:** Remove the startup block entirely.

---

## 3. Stale Comments / Documentation

### 3a. `media-tools.nix` — powermenu suspend

```nix
pkgs.playerctl  # media playback control (used by powermenu suspend)
```

The Walker powermenu has no `suspend` option. `playerctl` is still useful for
general media control, but the comment is stale.

**Fix:** Change to `# media playback control (used by waybar mpris + media keys)`.

### 3b. `docs/for-agents/001-repo-map.md` — `session-applets.nix` description

```text
`desktop/session-applets.nix` — Hyprland user session agents/applets
(hyprpolkitagent, nm-applet, blueman-applet, udiskie)
```

`blueman-applet` is **not** a user service defined in session-applets; it's
handled by `services.blueman` in `modules/features/system/bluetooth.nix`
(a NixOS-level service). The `hyprland.nix` reset-failed list does reference
`blueman-applet.service`, which works (unknown units don't error), but is
technically not in-scope for the description.

**Fix:** Remove `blueman-applet` from the description (or note it's system-level).

### 3c. `hyprland.nix` reset-failed — `blueman-applet.service`

The reset-failed list includes `blueman-applet.service` but no user service of
that name is created by this repo. It won't cause errors (systemd ignores unknown
units in reset-failed), but it's semantically misleading.

**Fix:** Either remove from reset-failed list or accept as a safety net for
the NixOS `services.blueman` unit.

---

## 4. Config / Code Quality

### 4a. Walker powermenu configs: single `menus:default` action key

The confirmation submenus use `actions = { "menus:default" = "..." }`. This
works but the Elephant README shows a convention where the action key matches
the entry text (e.g., `"menus:default"` for the implicitly selected entry).
The current approach is correct and functional — no change needed.

### 4b. Waybar powermenu button uses `walker --provider menus:powermenu`

This launches a new Walker instance each click instead of reusing the running
service. Walker's `--gapplication-service` mode should handle this via D-Bus
activation, but the explicit `walker --provider` bypasses the service. The
behavior is correct (it opens the picker), but there is a minor UX hit: the
popover animation is visible each time instead of the pre-cached window.

**Discussion:** Could use `walker --provider menus:powermenu --single-instance`
if supported, or leave as-is.

---

## 5. Docs Cleanliness

### 5a. Rofi removal is complete

Zero references to `rofi` remain in active code or `docs/for-agents/001-repo-map.md`.
The `docs/for-agents/plans/095-remove-rofi.md` plan can be archived after execution
confirmation.

### 5b. No orphaned `docs/for-agents/current/` or `plans/`

Only the scaffold files and plan 095 exist. No stale progress logs.

### 5c. Archive bloat check

`docs/for-agents/archive/` contains 20+ plans/logs/reports from earlier work
(plan 081 through 094). These are all archived and can stay — they provide
historical context. No action needed.

---

## 6. Flake / Input Hygiene

All flake inputs are properly declared and used:

| Input | Consumer |
|-------|----------|
| `catppuccin-zen-browser-src` | `pkgs/catppuccin-zen-browser.nix` |
| `spicetify-nix` | `music-client.nix` |
| `waypaper-src` | `waypaper.nix` |
| `rmpc` | `pkgs/default.nix` → `music-client.nix` |
| `keyrs` | predator host composition |

No unused inputs. No satty, nwg-dock, or other stale references in `flake.lock`.

---

## 7. Summary of Recommended Actions

### Must fix (functional impact)
| # | Item | Severity |
|---|------|----------|
| 1 | Remove `hypr-dock` zombie from `startup.lua` | Medium |
| 2 | Sync `appearance.lua` alpha value live → repo | Medium |
| 3 | Sync `input.lua` `follow_mouse` live → repo | Medium |
| 4 | Sync `rules.lua` `ignore_alpha` live → repo | Low |
| 5 | Sync `waybar/config` live → repo | Medium |
| 6 | Sync `waybar/style.css` live → repo | Medium |

### Should fix (cleanliness)
| # | Item | Severity |
|---|------|----------|
| 7 | Update `media-tools.nix` stale comment | Low |
| 8 | Fix `session-applets.nix` description in repo-map (blueman) | Low |
| 9 | Sync `layout.lua` whitespace live → repo | Trivial |

### Optional / Discussion
| # | Item |
|---|------|
| 10 | Consider `--single-instance` for powermenu Walker call |
| 11 | Remove `blueman-applet.service` from hyprland reset-failed list |
| 12 | Remove dead `/*#custom-powermenu,*/` in waybar style |
