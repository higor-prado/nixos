# Plan 097: Post-Audit Repo Sync (Live → Repo)

**Status:** planning
**Date:** 2026-04-29
**Parent:** Report 096 — Comprehensive Repo Audit

## Rule

Live state is the source of truth. All changes sync live → repo. No changes to
live unless explicitly noted.

## Phase 1 — Critical Syncs (live → repo)

### 1. Remove `hypr-dock` zombie from `startup.lua`

**Repo and live:** `config/desktops/hyprland-standalone/modules/startup.lua`
and `~/.config/hypr/modules/startup.lua`

Currently calls `hl.exec_cmd("hypr-dock")` on every Hyprland start. Binary does
not exist. nwg-dock-hyprland was removed in commit `3546623`.

**Action:** Remove the `hl.on("hyprland.start", ...)` block entirely (empty
startup module is fine).

### 2. Sync `appearance.lua` shadow color alpha

| File | Line | Value |
|------|------|-------|
| Live `~/.config/hypr/modules/appearance.lua` | 39 | `color = "0xddb4befe"` |
| Repo `config/desktops/hyprland-standalone/modules/appearance.lua` | 39 | `color = "0xffb4befe"` |

**Action:** Copy live to repo. Updates `decoration.shadow.color` alpha from opaque
to 87% transparency.

### 3. Sync `input.lua` follow_mouse

| File | Line | Value |
|------|------|-------|
| Live | 10 | `follow_mouse = 2` |
| Repo | 10 | `follow_mouse = 1` |

**Action:** Copy live to repo.

### 4. Sync `rules.lua` waybar-blur ignore_alpha

| File | Line | Value |
|------|------|-------|
| Live | 39 | `ignore_alpha = 0.39` |
| Repo | 39 | `ignore_alpha = 0.49` |

**Action:** Copy live to repo.

### 5. Sync `layout.lua` whitespace

Minor diff: live has a blank line after line 11, repo doesn't.

**Action:** Copy live to repo.

### 6. Sync `waybar/config` — group name + minor diffs

| Field | Live | Repo |
|-------|------|------|
| modules-center group | `group/audiogroup` | `group/audio` |
| `max-length` | 36 | 40 |
| `format` (volume) | `{icon} {volume}%` | `{icon}  {volume}%` |
| trailing `align` | absent | `"align": 0` |

**Action:** Copy live to repo.

### 7. Sync `waybar/style.css` — dead CSS + missing selectors

Repo has dead selectors absent from live:
- `/*#custom-powermenu,*/` (commented out)
- `#hardware > widget { ... }` rules

Live has selectors absent from repo:
- `#mpris, #pulseaudio { min-width: 56px; }`

Repo uses `#audio` but live uses `#audiogroup` (must match config).

**Action:** Copy live to repo.

## Phase 2 — Stale Comments

### 8. Update `media-tools.nix` comment

```nix
# Before: pkgs.playerctl  # media playback control (used by powermenu suspend)
# After:  pkgs.playerctl  # media playback control (waybar mpris + media keys)
```

### 9. Update `docs/for-agents/001-repo-map.md` — session-applets description

Remove `blueman-applet` from description since it's a system-level service
(not a user applet in session-applets.nix):

```
# Before: (hyprpolkitagent, nm-applet, blueman-applet, udiskie)
# After:  (hyprpolkitagent, nm-applet, udiskie)
```

### 10. Archive plan 095 (remove-rofi) — already executed

Move `docs/for-agents/plans/095-remove-rofi.md` to
`docs/for-agents/archive/plans/095-remove-rofi.md`.

## Phase 3 — Validation

```bash
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Apply live: `hyprctl reload`, restart waybar.

## Commits

All syncs in one commit:

```
fix(desktop): sync live config drift from post-audit

- Remove hypr-dock zombie from startup.lua
- Sync decoration shadow alpha, follow_mouse, waybar blur alpha
- Sync waybar config (audiogroup naming, max-length, volume format)
- Sync waybar style (remove dead CSS, add mpris/pulseaudio min-width)
- Update stale media-tools comment and session-applets docs
- Archive plan 095 (remove-rofi)
```

## Out of scope

- hyprlock (not installed, never was — report error corrected)
- blueman-applet from hyprland.nix reset-failed (harmless safety net)
- Walker powermenu `--single-instance` (cosmetic, no functional impact)
