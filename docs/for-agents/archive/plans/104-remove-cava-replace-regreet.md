# Remove Cava and Replace ReGreet with Tuigreet

## Goal

Remove the unused Cava audio visualizer, replace the regreet greeter with the
simpler `tuigreet` (keeping greetd as the display manager), and confirm
hyprpolkitagent is already properly installed.

## Scope

In scope:
- Remove `media-cava.nix` feature module and its import from predator
- Remove `catppuccin.cava.enable` from `theme-base.nix`
- Replace regreet greeter with tuigreet in `regreet.nix` (rename to `greetd.nix`)
- Simplify greeter config — tuigreet needs zero theming
- Update `001-repo-map.md`

Out of scope:
- Switching display manager (greetd stays)
- Hyprpolkitagent installation (already present in `session-applets.nix`)
- Any other feature changes

## Current State

### Cava
- `modules/features/desktop/media-cava.nix` — publishes `homeManager.media-cava` with cava audio visualizer config
- Imported by predator: `homeManager.media-cava` in `hmDesktop`
- Themed: `catppuccin.cava.enable = true` in `theme-base.nix:31`
- **Not actually used** — the user confirmed cava is not being used

### ReGreet → Tuigreet
- `modules/features/desktop/regreet.nix` — publishes `nixos.regreet`, configures greetd with:
  - regreet greeter program
  - GTK theme, cursor, icon theme, font
  - Custom CSS
  - Catppuccin mocha wallpaper background
- Imported by predator: `nixos.regreet` in `nixosDesktop`
- Tuigreet is a terminal-based greeter for greetd — zero graphical theming required

### Hyprpolkitagent
- Already enabled: `services.hyprpolkitagent.enable = true` in `session-applets.nix:8`
- Already configured as a systemd user service with `ConditionEnvironment=WAYLAND_DISPLAY` and `Restart=on-failure`
- The hyprland session-start script already stops/resets/starts `hyprpolkitagent.service`
- **No action needed** — already fully integrated

## Desired End State

- `media-cava.nix` deleted; zero references to cava in tracked code
- `regreet.nix` replaced by `greetd.nix` using tuigreet
- Greetd config: minimal — just the command to launch Hyprland, no theming
- `catppuccin.cava.enable` removed from `theme-base.nix`
- Repo map updated
- Predator evaluates and builds correctly

## Phases

### Phase 1: Remove cava

Targets:
- `modules/hosts/predator.nix` — remove `homeManager.media-cava` from `hmDesktop`
- `modules/features/desktop/theme-base.nix` — remove `catppuccin.cava.enable = true;`
- `modules/features/desktop/media-cava.nix` — delete file
- `docs/for-agents/001-repo-map.md` — remove `media-cava.nix` entry

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `chore(desktop): remove unused cava audio visualizer`

---

### Phase 2: Replace regreet with tuigreet

Replace the entire regreet greeter config with a minimal tuigreet greeter.
Tuigreet is a terminal-based greeter — no GTK theming, no CSS, no wallpaper.

Targets:
- `modules/features/desktop/regreet.nix` — replace content (rename to greetd.nix)
- `modules/hosts/predator.nix` — update import name `nixos.regreet` → `nixos.greetd`

New module content (`modules/features/desktop/greetd.nix`):

```nix
{ config, pkgs, ... }:
{
  flake.modules.nixos.greetd =
    { ... }:
    let
      userName = config.username;
      tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
      hyprlandSession = "${pkgs.hyprland}/bin/Hyprland";
    in
    {
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${tuigreet} --greeting 'Welcome back' --remember --remember-session --time --cmd ${hyprlandSession}";
            user = "greeter";
          };
        };
      };
    };
}
```

Note: `config.username` is read at the top level (before publishing the
lower-level module). This follows the host-aware pattern — capture facts
from the owning module scope, then use them inside the lower-level module.

Changes in `predator.nix`:
- `nixos.regreet` → `nixos.greetd` in `nixosDesktop` list

Delete old file:
- `modules/features/desktop/regreet.nix`

Docs:
- `docs/for-agents/001-repo-map.md` — update entry from `desktop/regreet.nix` to `desktop/greetd.nix`

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`
- Verify greetd service is enabled in the evaluated config:
  ```bash
  nix eval path:$PWD#nixosConfigurations.predator.config.services.greetd.enable
  ```

Commit target:
- `refactor(desktop): replace regreet with tuigreet greeter`

---

### Phase 3: Final validation

- All three hosts eval
- 13/13 validation gates
- Repo map updated
- No stale references to regreet or cava

Commit target:
- `docs(repo-map): update for cava removal and regreet→greetd migration`

## Risks

- **Greetd+tuigreet compatibility**: Tuigreet uses `--cmd` to launch the session.
  The current regreet config uses `command` with the session directly. Need to
  verify the tuigreet CLI flags are correct for the NixOS greetd module.
- **NixOS module name change**: Renaming `nixos.regreet` to `nixos.greetd` is a
  breaking change for the import name, but predator is the only consumer.
- **Hyprpolkitagent**: Already installed — no risk. Confirming for completeness.

## Definition of Done

- [ ] `media-cava.nix` deleted, zero references remain
- [ ] `catppuccin.cava.enable` removed from theme-base.nix
- [ ] `regreet.nix` replaced by `greetd.nix` with tuigreet
- [ ] `nixos.greetd` imported by predator (renamed from `nixos.regreet`)
- [ ] Predator eval passes
- [ ] All validation gates pass
- [ ] Repo map updated
- [ ] Hyprpolkitagent confirmed present (no action needed)
