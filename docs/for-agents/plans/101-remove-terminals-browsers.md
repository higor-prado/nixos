# Remove Redundant Terminals and Browsers

## Goal

Trim the terminal and browser roster to a lean set, removing unused packages,
their HM modules, catppuccin themes, MIME handler entries, and all downstream
references in scripts, configs, and docs.

## Scope

In scope:
- Remove 3 terminals: ghostty, alacritty, wezterm
- Remove 3 browsers: floorp, vivaldi, google-chrome
- Clean up catppuccin theme entries for removed apps
- Clean up MIME/xdg handler lists
- Clean up waybar active-window script
- Clean up hyprland binds/rules (if any reference removed apps)
- Clean up documentation references
- Validate builds pass for predator, aurelius, cerebelo

Out of scope:
- Changes to kitty, foot configuration
- Changes to firefox, chromium, brave, zen-browser configuration
- Ananicy rules (managed outside the repo)
- NVIDIA VRAM profile (none of the removed apps are listed)
- Private user configs under `private/`

## Current State

### Terminals (5 total)

| Terminal | Module | Theme | Other refs |
|----------|--------|-------|------------|
| kitty | `modules/features/shell/terminals.nix` (L45-60) | `catppuccin.kitty.enable` in `theme-base.nix` L26 | `$TERMINAL` env var, elephant `terminal_cmd`, hyprland scratchpad, waybar script |
| foot | `modules/features/shell/terminals.nix` (L22-32) | `catppuccin.foot.enable` in `theme-base.nix` L24, footTheme derivation | waybar script |
| ghostty | `modules/features/shell/terminals.nix` (L34-43) | `catppuccin.ghostty.enable` in `theme-base.nix` L25 | waybar script, D-Bus duplicate warning in plan 100 |
| alacritty | `modules/features/shell/terminals.nix` (L62-84) | `catppuccin.alacritty.enable` in `theme-base.nix` L23 | waybar script |
| wezterm | `modules/features/shell/terminals.nix` (L86-109) | `catppuccin.wezterm.enable` in `theme-base.nix` L27 | docs/for-agents/001-repo-map.md L52, archive/log-tracks/001 L511 |

### Browsers (7 total)

| Browser | Module | Theme | Other refs |
|---------|--------|-------|------------|
| firefox | `modules/features/desktop/desktop-apps.nix` (L19-31) | `catppuccin.firefox` in `theme-base.nix` L31-34 | MIME default handler, hyprland binds, waybar script |
| chromium | `modules/features/desktop/desktop-apps.nix` (L33-40) | `catppuccin.chromium.enable` in `theme-base.nix` L28 | waybar script |
| brave | `modules/features/desktop/desktop-apps.nix` (L41-48) | `catppuccin.brave.enable` in `theme-base.nix` L29 | MIME removed list, desktop-viewers nonFirefoxWebHandlers, waybar script |
| zen-browser | `desktop-apps.nix` L75 (home.packages) | `modules/features/desktop/theme-zen.nix` (sync script) | MIME removed list, waybar script |
| floorp | `desktop-apps.nix` (L49-59) | `catppuccin.floorp` in `theme-base.nix` L35-38 | MIME removed list, waybar script |
| vivaldi | `desktop-apps.nix`` (L61-72) | `catppuccin.vivaldi.enable` in `theme-base.nix` L30 | MIME removed list, waybar script |
| google-chrome | `desktop-apps.nix` L76-82 (home.packages) | none | MIME removed list, desktop-viewers nonFirefoxWebHandlers, waybar script |

### Key files to modify

1. `modules/features/shell/terminals.nix` — remove ghostty, alacritty, wezterm blocks
2. `modules/features/desktop/desktop-apps.nix` — remove floorp, vivaldi, google-chrome
3. `modules/features/desktop/theme-base.nix` — remove catppuccin entries for removed apps
4. `modules/features/desktop/desktop-viewers.nix` — clean nonFirefoxWebHandlers list
5. `config/apps/waybar/scripts/active-window.sh` — remove ghostty/alacritty from terminal case, floorp/vivaldi/google-chrome from browser cases
6. `docs/for-agents/001-repo-map.md` — update terminals description

### Files that need no changes

- `config/apps/elephant/elephant.toml` — uses `kitty` only, no change needed
- `config/desktops/hyprland-standalone/modules/binds.lua` — no references to removed apps
- `config/desktops/hyprland-standalone/modules/rules.lua` — scratchpad uses `kitty`, no change
- `hardware/predator/hardware/gpu-nvidia.nix` — no removed apps in NVIDIA VRAM profile
- `modules/features/desktop/theme-zen.nix` — zen-browser stays, no change

## Desired End State

- Terminals: kitty (primary, `$TERMINAL`), foot (secondary)
- Browsers: firefox (default MIME handler), chromium, zen-browser, brave
- No catppuccin theme entries for removed apps
- No MIME handler references to removed browsers
- Waybar script cases updated to match remaining apps only
- Docs reflect the current set

## Phases

### Phase 0: Baseline

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion` passes
- Working tree clean

### Phase 1: Remove terminal programs and themes

Targets:
- `modules/features/shell/terminals.nix`
- `modules/features/desktop/theme-base.nix`

Changes:
- Remove `programs.ghostty` block (L34-43)
- Remove `programs.alacritty` block (L62-84)
- Remove `programs.wezterm` block (L86-109)
- Remove `catppuccin.alacritty.enable = true` (L23)
- Remove `catppuccin.ghostty.enable = true` (L25)
- Remove `catppuccin.wezterm.enable = true` (L27)

Validation:
- `nix build --dry-run path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- No evaluation errors

Diff expectation:
- 3 program blocks removed from terminals.nix
- 3 catppuccin lines removed from theme-base.nix

Commit target:
- `refactor(shell): remove ghostty, alacritty, wezterm terminals`

### Phase 2: Remove browser programs and themes

Targets:
- `modules/features/desktop/desktop-apps.nix`
- `modules/features/desktop/theme-base.nix`

Changes:
- Remove `programs.floorp` block (L49-59)
- Remove `programs.vivaldi` block (L61-72)
- Remove `google-chrome` from `home.packages` (L76-82)
- Remove `catppuccin.vivaldi.enable = true` (L30)
- Remove `catppuccin.floorp.profiles.default` block (L35-38)
- Remove `"vivaldi-stable.desktop"` from nonFirefoxWebHandlers
- Remove `"floorp.desktop"` from nonFirefoxWebHandlers
- Remove `"com.google.Chrome.desktop"` from nonFirefoxWebHandlers
- Remove `"google-chrome.desktop"` from nonFirefoxWebHandlers

Validation:
- `nix build --dry-run path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- 3 browser configurations removed from desktop-apps.nix
- 4 MIME entries removed from nonFirefoxWebHandlers
- 2 catppuccin blocks removed from theme-base.nix

Commit target:
- `refactor(desktop): remove floorp, vivaldi, google-chrome browsers`

### Phase 3: Clean up MIME handlers and scripts

Targets:
- `modules/features/desktop/desktop-viewers.nix`
- `config/apps/waybar/scripts/active-window.sh`

Changes:
- In `desktop-viewers.nix`: remove `"google-chrome.desktop"` from nonFirefoxWebHandlers
- In `active-window.sh`:
  - L72: change `zen*|floorp*)` to `zen*)`
  - L77: change `chromium-browser|chromium*|google-chrome*|brave-browser*|vivaldi*)` to `chromium-browser|chromium*|brave-browser*`
  - L97: change `kitty|foot|alacritty|ghostty)` to `kitty|foot)`

Validation:
- `nix build --dry-run path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Commit target:
- `fix(desktop): clean up mime handlers and waybar script for removed apps`

### Phase 4: Update documentation

Targets:
- `docs/for-agents/001-repo-map.md`

Changes:
- Update terminals line from "foot, ghostty, kitty, alacritty, wezterm" to "foot, kitty"

Validation:
- `bash scripts/check-docs-drift.sh`

Commit target:
- `docs: update repo map for current terminal and browser set`

### Phase 5: Full validation

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `bash scripts/run-validation-gates.sh`
- `bash scripts/check-repo-public-safety.sh`

## Risks

- **Closure size**: Removing packages reduces closure size; no risk of bloat.
- **Runtime configs**: User may have local browser profiles (firefox, zen) — not affected.
- **Google-chrome MIME desktop ID**: Removing `google-chrome.desktop` and `com.google.Chrome.desktop` from nonFirefoxWebHandlers means chromium's `chromium-browser.desktop` still covers the Chromium-based handler slot.
- **Floorp zen detection in waybar**: `floorp` was grouped with `zen*` in the waybar script. Removing `floorp` from that case is safe since floorp is being removed entirely.

## Definition of Done

- [ ] No HM/NixOS module enables or configures ghostty, alacritty, wezterm, floorp, vivaldi, or google-chrome
- [ ] No catppuccin theme entry references a removed app
- [ ] No MIME handler lists reference removed browser desktop IDs
- [ ] Waybar active-window.sh only matches remaining terminals and browsers
- [ ] `001-repo-map.md` reflects the current set
- [ ] All validation gates pass for predator, aurelius, cerebelo
- [ ] Working tree clean
