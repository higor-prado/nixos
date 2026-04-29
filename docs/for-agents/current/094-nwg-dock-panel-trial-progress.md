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

Status: not started

Planned changes:
- add small test launch scripts only if useful
- avoid autostart
- keep scripts shellchecked and obvious

Validation to record:
- `bash -n`
- `shellcheck -x` if available
- HM build
- structure gate

Commit target:
- `feat(desktop): add nwg trial launch helpers`

### Slice 3 — Theme/config trial

Status: not started

Planned changes:
- live-first NWG config/theme testing
- sync to repo only after a useful live state is proven
- derive theme colors from existing theme catalog where practical

Validation to record:
- manual dock launch
- manual panel launch
- manual clipman launch
- check Waybar/Rofi/current clipboard UI remain intact
- HM build and structure gate if repo payloads are added

Commit target:
- `feat(desktop): add themed nwg trial config` if repo payloads are added

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

Not reached. This log currently records the planned trial only.
