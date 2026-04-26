# Hyprland App Parity and Theme Coherence Plan

## Goal

Add the requested missing Hyprland desktop support apps (excluding brightness control and night-light filtering), wire them using the repo ownership pattern, and apply Catppuccin/theme coherence wherever supported by the current module stack. Validate and, if needed, fix greeter-theme coherence with the rest of the desktop theme model.

Cursor policy decision (latest): keep the existing `phinger-cursors` choice and make it coherent across the whole system (session + greeter).

## Scope

In scope:
- Add and wire the requested apps:
  - `hyprpolkitagent`
  - `pamixer`
  - `cliphist`
  - `wl-clip-persist`
  - `satty`
  - `network-manager-applet`
  - `blueman` applet support
  - `udiskie`
  - `wlogout`
  - `hyprpicker`
  - `qt5ct`
  - `qt6ct`
  - `kvantum` + `kvantum-qt5`
- Apply Catppuccin theming where the repo/tooling supports it directly (e.g. wlogout, qt5ct/kvantum).
- Verify greeter theme coherence against the shared theme catalog and include a fix if incoherent.
- Keep host composition explicit in `modules/hosts/predator.nix`.
- Keep module ownership aligned with `docs/for-agents/003-module-ownership.md`.

Out of scope:
- `brightnessctl` (explicitly not requested)
- `hyprsunset` (explicitly not requested)
- migration to `uwsm`
- replacing ReGreet with SDDM
- introducing Dolphin/Ark KDE workflow
- forced rewrites of mutable copy-once runtime files under `$HOME` (Waybar/Hypr user files)

## Current State

- Predator currently uses Hyprland standalone composition with ReGreet.
- Audio/network/bluetooth foundations already exist:
  - PipeWire/WirePlumber enabled
  - NetworkManager enabled
  - Bluetooth stack enabled
- Requested HM services/programs are currently disabled in evaluated config:
  - `services.hyprpolkitagent`
  - `services.cliphist`
  - `services.wl-clip-persist`
  - `services.network-manager-applet`
  - `services.blueman-applet`
  - `services.udiskie`
  - `programs.satty`
  - `programs.wlogout`
  - `qt.enable`
- Existing tools coverage:
  - already present: `pavucontrol`, `playerctl`, `grim`, `slurp`, `wl-clipboard`
  - missing from repo runtime: `pamixer`, `hyprpicker`, above services/programs
- Greeter theme check (current):
  - ReGreet GTK theme name matches shared catalog (`catppuccin-mocha-lavender-standard`)
  - ReGreet icon/font align with shared catalog
  - ReGreet cursor uses Catppuccin cursor from catalog
  - HM session cursor currently uses `phinger-cursors`, not catalog cursor
- Conclusion: greeter theming is mostly correct, but cursor policy is not fully coherent across greeter vs session.

## Desired End State

- Requested app set is declaratively enabled and wired in the correct feature owners.
- Session applet/agent services start reliably in Hyprland user session.
- Catppuccin theming is applied where supported:
  - `catppuccin.wlogout.enable = true`
  - Catppuccin for Qt path via qt5ct/kvantum support
- Greeter and session cursor policy is coherent through a single source (theme catalog), using `phinger-cursors`.
- Predator host imports explicitly include any new HM feature modules.
- Structure/all validation gates pass.

## Phases

### Phase 0: Baseline and feature contract snapshot

Targets:
- no code changes

Changes:
- record baseline eval snapshot for current missing apps/services and theme values
- confirm current greeter/session theme values before edits

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.regreet`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.gtk`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.pointerCursor`

Diff expectation:
- none

Commit target:
- none

### Phase 1: Add session agents/applets/clipboard owners

Targets:
- `modules/features/desktop/session-applets.nix` (new)
- `modules/features/system/bluetooth.nix`
- `modules/hosts/predator.nix`

Changes:
- add a dedicated HM feature owner for user-session applets/agents:
  - `services.hyprpolkitagent.enable = true`
  - `services.network-manager-applet.enable = true`
  - `services.blueman-applet.enable = true`
  - `services.udiskie.enable = true`
  - `services.cliphist.enable = true`
  - `services.wl-clip-persist.enable = true`
  - `xsession.preferStatusNotifierItems = true`
- ensure NixOS side blueman support is enabled in the narrow owner (`system/bluetooth.nix`):
  - `services.blueman.enable = true`
  - `services.blueman.withApplet = false`
- implementation note: disable NixOS-managed Blueman applet (`withApplet = false`) and let
  HM own `services.blueman-applet` startup to avoid duplicate `ExecStart` collision.
- import `homeManager.session-applets` in predator Hyprland HM composition list.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.hyprpolkitagent.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.network-manager-applet.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.blueman-applet.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.udiskie.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.cliphist.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.services.wl-clip-persist.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.services.blueman.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.services.blueman.withApplet`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- new user services and one additional bluetooth system service on predator

Commit target:
- `feat(desktop): add hyprland session applets, polkit agent, and clipboard services`

### Phase 2: Add utility tools requested for Hyprland workflow

Targets:
- `modules/features/desktop/media-tools.nix`
- `modules/features/desktop/wayland-tools.nix`
- `modules/features/desktop/satty.nix` (new)
- `modules/hosts/predator.nix`

Changes:
- add `pamixer` to media tools owner
- add `hyprpicker` to wayland tools owner
- add dedicated satty owner with HM program module:
  - `programs.satty.enable = true`
  - minimal declarative satty settings (stable defaults)
- import `homeManager.satty` in predator Hyprland HM composition.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.satty.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages --apply 'ps: map (p: p.pname or p.name or "") ps' | jq -r '.[]' | rg 'pamixer|hyprpicker|satty'`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- added user packages and satty config surface

Commit target:
- `feat(desktop): add pamixer, hyprpicker, and satty tooling`

### Phase 3: Add wlogout + Qt theming stack with Catppuccin

Targets:
- `modules/features/desktop/wlogout.nix` (new)
- `modules/features/desktop/qt-theme.nix` (new)
- `modules/hosts/predator.nix`

Changes:
- add dedicated wlogout owner:
  - `programs.wlogout.enable = true`
  - `catppuccin.wlogout.enable = true`
- add dedicated Qt theme owner:
  - enable HM Qt integration (`qt.enable = true`)
  - set Qt style/theme path to kvantum/qtct-compatible setup
  - install/request `qt5ct`, `qt6ct`, `kvantum`, `kvantum-qt5` via HM owner
  - enable Catppuccin integrations available in current stack:
    - `catppuccin.qt5ct.enable = true`
    - `catppuccin.kvantum.enable = true`
- import `homeManager.wlogout` and `homeManager.qt-theme` in predator Hyprland HM composition.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.wlogout.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.catppuccin.wlogout.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.qt.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.catppuccin.qt5ct.enable`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.catppuccin.kvantum.enable`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- new HM desktop UX/theming modules and Qt theming runtime behavior

Commit target:
- `feat(theme): add wlogout and qt catppuccin theming stack`

### Phase 4: Greeter/session theme coherence fix

Targets:
- `modules/features/desktop/theme-base.nix`
- (optional comment alignment) `modules/features/desktop/_theme-catalog.nix`

Changes:
- align session cursor with shared theme catalog cursor:
  - make `home.pointerCursor` derive from `theme.cursorTheme`
- set shared theme catalog cursor to `phinger-cursors` so greeter/session converge on the existing cursor choice.
- keep ReGreet theme wiring in `regreet.nix` as-is (catalog-driven for GTK/icon/font/cursor).

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.regreet.cursorTheme.name`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.pointerCursor.name`
- assert both values equal expected shared catalog cursor name
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- visible cursor coherence between greeter and logged-in session

Commit target:
- `fix(theme): align greeter and session cursor with shared catalog`

### Phase 5: Docs sync + full validation + closure diff

Targets:
- `docs/for-agents/001-repo-map.md`
- `docs/for-humans/02-structure.md` (if feature list text needs updates)

Changes:
- document new desktop feature owners and purpose
- mention any intentional non-goals around mutable copy-once configs

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh all`
- mandatory Nix gates from AGENTS:
  - `nix flake metadata`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- closure diff (behavior slice):
  - `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-new`
  - `nix run nixpkgs#nvd -- diff /tmp/predator-baseline /tmp/predator-new`

Diff expectation:
- docs aligned with new feature surface; full validation green

Commit target:
- `docs: update repo map for hyprland app parity modules`

## Risks

- Tray UX duplication/noise from running Waybar modules plus applet daemons.
- Qt theming can be sensitive across mixed Qt5/Qt6 apps; requires careful defaults.
- Clipboard daemons can interfere with existing custom clipboard scripts if any local runtime customization exists.
- Copy-once mutable files (`waybar`, `hypr user.conf`) may require manual user merge for click-actions/keybind behavior changes.
- Cursor coherence fix changes visible cursor style in-session (from phinger -> catalog cursor).

## Definition of Done

- All requested apps (minus brightness/night-light exclusions) are declaratively present and enabled in correct owners.
- Predator Hyprland HM import list includes the new module owners explicitly.
- Catppuccin is applied where first-class support exists (wlogout, qt5ct/kvantum).
- Greeter/session cursor policy is coherent via one source of truth.
- `./scripts/run-validation-gates.sh all` passes.
- AGENTS mandatory eval/build gates pass.
- Docs reflect the new module surface.
