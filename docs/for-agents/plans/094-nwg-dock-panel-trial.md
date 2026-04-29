# NWG Dock, Panel, and Clipman Trial

## Goal

Add `nwg-dock-hyprland`, `nwg-panel`, and `nwg-clipman` to the `predator` Hyprland user environment in a repo-native, reversible way so the user can test them without disrupting the current Waybar/Rofi/Hyprland session. Preserve Catppuccin/GTK/icon theme coherence where possible and keep all mutable config trial surfaces explicit.

## Scope

In scope:
- install `pkgs.nwg-dock-hyprland`, `pkgs.nwg-panel`, and `pkgs.nwg-clipman` for the tracked user on `predator`
- create a narrow Home Manager feature owner under `modules/features/desktop/`
- wire the feature explicitly in `modules/hosts/predator.nix`
- decide whether the feature should only install packages first or also provision optional test scripts/config
- keep current Waybar as the primary panel while testing `nwg-panel`
- keep current Rofi powermenu and app launcher behavior unchanged
- keep the current Rofi/Waybar clipboard history path unchanged while allowing `nwg-clipman` to be tested as a replacement clipboard UI
- apply theme-compatible defaults/config if feasible without over-owning generated NWG files
- document any mutable-copy/live-first workflow for NWG configs
- validate builds and live launch commands

Out of scope:
- replacing Waybar with `nwg-panel`
- replacing Rofi launchers/powermenu
- removing the existing Rofi/Waybar clipboard manager path before `nwg-clipman` is tested and accepted
- changing Hyprland layout/rules broadly for the dock
- introducing generic desktop selectors or feature enable booleans
- changing theme catalog values
- reading or editing private files
- adding autostart by default before the user has tested runtime behavior

## Current State

Repo facts:
- active desktop is Hyprland standalone on `predator`
- host composition is explicit in `modules/hosts/predator.nix`
- desktop/user packages belong in Home Manager feature modules
- mutable/copy-once config payloads live under `config/` and are synced live-first when they represent editable runtime config
- current panel/status bar is Waybar, owned by `modules/features/desktop/waybar.nix` and `config/apps/waybar/`
- current launcher/powermenu is Rofi, owned by `modules/features/desktop/rofi.nix`
- theme constants live in `modules/features/desktop/_theme-catalog.nix`

Package availability checked:
- `nixpkgs#nwg-dock-hyprland` exists; `pname = "nwg-dock-hyprland"`
- `nixpkgs#nwg-panel` exists; `pname = "nwg-panel"`
- `nixpkgs#nwg-clipman` exists; `pname = "nwg-clipman"`
- `nwg-dock-hyprland --help` exposes useful test flags such as:
  - `-s <css>` for style
  - `-i <size>` for icon size
  - `-p <position>` for dock position
  - `-d` for autohide/hotspot behavior
  - `-nolauncher` to avoid adding a launcher button
  - `-g <classes>` to ignore classes
- `nwg-panel --help` exposes:
  - `-c <config>`
  - `-s <style>`
  - `-r` restore default config files
- `nwg-clipman --help` exposes:
  - `-n` / `--numbers` to show item numbers
  - `-w` / `--window` to run in a regular window instead of layer shell

Important observation:
- Running `nix run nixpkgs#nwg-panel -- --help` created `~/.config/nwg-panel` as a side effect. That directory was removed during planning to avoid leaving unmanaged live junk. Any future live NWG config generation must be intentional and recorded.

## Desired End State

- `predator` Home Manager includes `nwg-dock-hyprland`, `nwg-panel`, and `nwg-clipman` via a narrow desktop feature module.
- The user can launch the tools manually for tests without a rebuild-time autostart surprise.
- Current Waybar and Rofi behavior remains unchanged.
- If theme files are added, they derive from existing Catppuccin/theme catalog values where practical.
- Any generated NWG config is either intentionally ignored as local mutable trial state or promoted to tracked `config/apps/nwg-*` payloads after live testing.
- Validation gates pass.

## Phases

### Phase 0: Baseline and package behavior inventory

Targets:
- no repo changes beyond this plan/log track
- runtime inspection only

Changes:
- confirm clean worktree
- inspect package metadata and CLI flags
- verify whether Home Manager has first-class options for NWG tools; if not, package install/scripts are enough for first trial
- note side effects of launching `nwg-panel`; remove any accidental generated live config before implementation

Validation:
- `git status --short`
- `nix eval --raw nixpkgs#nwg-dock-hyprland.pname`
- `nix eval --raw nixpkgs#nwg-panel.pname`
- `nix eval --raw nixpkgs#nwg-clipman.pname`
- `nix run nixpkgs#nwg-dock-hyprland -- --help`
- `nix run nixpkgs#nwg-panel -- --help`
- `nix run nixpkgs#nwg-clipman -- --help`

Diff expectation:
- docs-only if committing the plan/log first

Commit target:
- `chore(agents): add nwg dock panel clipman trial plan`

### Phase 1: Add feature owner for NWG test tools

Targets:
- new `modules/features/desktop/nwg-shell.nix` or similarly named owner
- `modules/hosts/predator.nix`
- `docs/for-agents/001-repo-map.md` if a new feature owner is added

Changes:
- publish `flake.modules.homeManager.nwg-shell` or another clearly named lower-level HM module
- add only user-interactive packages initially:
  - `pkgs.nwg-dock-hyprland`
  - `pkgs.nwg-panel`
  - `pkgs.nwg-clipman`
- wire `homeManager.nwg-shell` explicitly into the `predator` HM desktop imports
- do not add autostart yet
- do not add broad options; host import is the condition

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- one feature module
- one host import
- repo map line if needed

Commit target:
- `feat(desktop): add nwg trial tools`

### Phase 2: Add optional test launch helpers

Targets:
- possible tracked scripts under `config/apps/nwg-shell/`
- `modules/features/desktop/nwg-shell.nix`

Changes:
- add small explicit launch scripts only if they reduce manual command friction
- likely scripts:
  - `nwg-dock-test.sh` to launch the dock in non-autostart test mode
  - `nwg-panel-test.sh` to launch panel with explicit config/style if those are added later
  - `nwg-clipman-test.sh` or a documented command to launch the alternative clipboard UI against the existing clipboard history stack
- keep scripts in Home Manager path or provisioned under `~/.config/nwg-shell/` via copy-once only if needed
- make scripts safe to re-run, e.g. kill existing dock/panel instance or focus/exit cleanly

Validation:
- `bash -n` on scripts
- `shellcheck -x` on scripts when available
- Home Manager build
- structure gate

Diff expectation:
- optional scripts only; no generated NWG config yet unless Phase 3 requires it

Commit target:
- `feat(desktop): add nwg trial launch helpers`

### Phase 3: Theme/config trial, live-first

Targets:
- live generated config under `~/.config/nwg-panel/` and/or `~/.config/nwg-dock-hyprland/`
- possible tracked payloads under:
  - `config/apps/nwg-panel/`
  - `config/apps/nwg-dock-hyprland/`
- `modules/features/desktop/nwg-shell.nix`

Changes:
- generate or write the minimal live config needed for testing
- apply Catppuccin-compatible colors using existing theme catalog values where possible
- avoid duplicating the entire current Waybar configuration unless actually replacing it later
- if a live config proves useful, sync live → repo into `config/apps/nwg-*` and provision copy-once
- if configs are purely exploratory, leave them untracked and document them as local trial state

Validation:
- launch `nwg-dock-hyprland` manually on the live Hyprland session
- launch `nwg-panel` manually without disabling Waybar
- verify no conflict with Waybar, Rofi, Mako, tray applets, current cliphist capture, or Hyprland special workspace binds
- verify visual theme is acceptable enough for testing
- Home Manager build if repo payloads are added
- structure gate

Diff expectation:
- either no repo diff, or tracked minimal theme/config payloads plus provisioning

Commit target:
- `feat(desktop): add themed nwg trial config` if repo payloads are added

### Phase 4: Runtime acceptance and autostart decision

Targets:
- live session only unless user requests declarative autostart
- possible Hyprland Lua startup owner if autostart is explicitly approved later

Changes:
- test dock/panel/clipman manually for at least one session
- decide:
  - keep as manually launched test tools
  - add keybind(s) for trial launch
  - add user service(s)
  - add Hyprland startup entries
  - remove if not useful
- no autostart without explicit user approval after live testing

Validation:
- live smoke test:
  - dock starts/stops cleanly
  - panel starts/stops cleanly
  - clipman opens and can select/paste history without disabling current Rofi/Waybar clipboard UI
  - Waybar remains intact
  - no duplicate tray/notification/polkit/network/bluetooth applet behavior
  - no unexpected focus/input regression with `keyrs`
- if autostart/service is added:
  - `systemctl --user status <unit>`
  - `journalctl --user -u <unit> --no-pager -n 100`
  - full validation gates

Diff expectation:
- decision-driven; no automatic change in this phase unless user approves

Commit target:
- `feat(desktop): add nwg dock panel autostart` only if approved
- `chore(desktop): keep nwg tools manual for trial` if documenting manual-only state

## Risks

- `nwg-panel` may create or mutate `~/.config/nwg-panel` on launch; live generated config must be treated carefully.
- `nwg-clipman` must be tested without disabling the current `cliphist` capture service or Rofi/Waybar clipboard UI until accepted.
- `nwg-panel` may duplicate Waybar functions/tray modules if started with default config.
- `nwg-dock-hyprland` may affect reserved screen space if launched with exclusive-zone flags.
- Dock/panel layer choices may interact with Waybar layer rules, blur rules, or Hyprland focus behavior.
- Theme parity may require CSS/config details not exposed declaratively by Home Manager.
- Autostart before testing could create login/session regressions, so it is intentionally deferred.

## Definition of Done

- `nwg-dock-hyprland`, `nwg-panel`, and `nwg-clipman` are available on `predator` through Home Manager.
- The feature owner is narrow and follows dendritic module publishing.
- Host wiring is explicit in `modules/hosts/predator.nix`.
- Waybar/Rofi remain unchanged unless explicitly approved later.
- Any NWG config payloads are either intentionally tracked or intentionally left as local mutable trial state.
- Theme approach is documented.
- Validation gates pass.
