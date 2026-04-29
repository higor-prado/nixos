# NWG Dock, Panel, and Clipman Trial Progress

## Status

Planned

## Related Plan

- [094-nwg-dock-panel-trial.md](/home/higorprado/nixos/docs/for-agents/plans/094-nwg-dock-panel-trial.md)

## Baseline

- Branch: `cleanup/hyprland-only`
- Current desktop: Hyprland standalone on `predator`
- Existing primary panel: Waybar
- Existing launcher/powermenu: Rofi
- User request: plan installation of `nwg-dock-hyprland` and `nwg-panel` for testing, keeping theme if possible and following repo philosophy
- Follow-up request: include `nwg-clipman` so it can be tested instead of the current Rofi clipboard manager UI
- Implementation has not started

Package inventory:

- `nixpkgs#nwg-dock-hyprland` exists and evaluates to `pname = "nwg-dock-hyprland"`
- `nixpkgs#nwg-panel` exists and evaluates to `pname = "nwg-panel"`
- `nixpkgs#nwg-clipman` exists and evaluates to `pname = "nwg-clipman"`
- `nwg-dock-hyprland --help` confirms CLI flags for manual dock testing, including style, icon size, position, autohide, launcher control, layers, and margins
- `nwg-panel --help` confirms CLI flags for config/style selection and restore mode
- `nwg-clipman --help` confirms CLI flags for numbers and regular-window mode

Side-effect note:

- Running `nix run nixpkgs#nwg-panel -- --help` created `~/.config/nwg-panel` directories.
- Those generated directories were removed immediately during planning because implementation has not started and unmanaged live config should not be left behind.

## Slices

### Slice 0 — Plan and log track creation

Status: completed

Changes made:
- created `docs/for-agents/plans/094-nwg-dock-panel-trial.md`
- created `docs/for-agents/current/094-nwg-dock-panel-trial-progress.md`
- updated plan/log to include `nwg-clipman`

Validation run:
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅

Diff result:
- docs-only active plan/log

Commit:
- pending: `chore(agents): add nwg dock panel clipman trial plan`

### Slice 1 — Feature owner and package install

Status: completed

Changes made:
- added `modules/features/desktop/nwg-shell.nix`
- installed manual-trial packages:
  - `pkgs.nwg-dock-hyprland`
  - `pkgs.nwg-panel`
  - `pkgs.nwg-clipman`
- wired `homeManager.nwg-shell` explicitly into `predator` HM desktop imports
- updated `docs/for-agents/001-repo-map.md`
- intentionally did not add autostart, services, keybinds, or replacement clipboard wiring

Validation run:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅ `"25.11"`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅

Diff result:
- one new feature module
- one host import
- repo map update

Commit target:
- `feat(desktop): add nwg trial tools`

### Slice 2 — Optional launch helpers

Status: completed

Changes made:
- added manual trial wrappers through `pkgs.writeShellApplication` in `modules/features/desktop/nwg-shell.nix`:
  - `nwg-dock-trial`
  - `nwg-panel-trial`
  - `nwg-clipman-trial`
- wrappers are installed through Home Manager packages
- avoided autostart, services, and keybinds

Validation run:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅

Manual commands after switch:
- `nwg-dock-trial`
- `nwg-panel-trial`
- `nwg-clipman-trial`

Commit target:
- `feat(desktop): add nwg trial launch helpers`

### Slice 3 — Theme/config trial

Status: completed for initial dock theme helper

Changes made:
- added `config/apps/nwg-shell/dock-catppuccin.css`
- wired the CSS as `~/.config/nwg-shell/dock-catppuccin.css`
- `nwg-dock-trial` launches `nwg-dock-hyprland` with the Catppuccin-compatible style
- did not generate or own `~/.config/nwg-panel`; panel remains default/manual for first live test
- did not replace the current Rofi/Waybar clipboard UI; `nwg-clipman-trial` is only an alternate manual UI over existing cliphist data

Validation run:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅

Commit target:
- `feat(desktop): add themed nwg trial helpers`

### Slice 4 — Runtime acceptance and autostart decision

Status: not started

Planned changes:
- test manually first
- decide whether to keep manual-only, add keybinds, add services, add startup, or remove
- no autostart without explicit user approval

Validation to record:
- live process/service checks depending on chosen path
- full validation if declarative startup is added

Commit target:
- decision-dependent

## Final State

Initial implementation is complete and still active for user runtime testing.

Available after activation/switch:
- packages:
  - `nwg-dock-hyprland`
  - `nwg-panel`
  - `nwg-clipman`
- manual wrappers:
  - `nwg-dock-trial` — themed dock, autohide, no launcher button
  - `nwg-panel-trial` — starts `nwg-panel` manually
  - `nwg-clipman-trial` — starts `nwg-clipman --numbers` over the existing cliphist history

Final validation run:
- `nix flake metadata path:$PWD` ✅
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion` ✅ `"25.11"`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅ `"25.11"`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `git diff --check` ✅

Activation attempt:
- `nh os switch path:$PWD --out-link "$HOME/.cache/nh-result-predator"` attempted
- build completed, activation failed because `sudo` required a terminal/password in the agent environment
- user still needs to run the switch interactively to make the tools available in the live profile

Remaining open:
- user runtime testing
- decide whether to keep manual-only, add keybinds, add autostart/services, replace the current Rofi clipboard UI with `nwg-clipman`, or remove the trial tools
