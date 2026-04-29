# NWG Dock Promotion and Vicinae Trial Progress

## Status

Implemented, pending interactive switch/runtime smoke

## Related Plan

- `docs/for-agents/plans/094-nwg-dock-panel-trial.md`

## Current Request

User correction:
- keep only the dock from the NWG trial
- remove `nwg-panel` and `nwg-clipman`
- fix `nwg-dock-trial` failure
- make dock config editable live
- promote the dock to autostart, no longer trial-only
- install `vicinae` for manual launcher testing

Pre-existing dirty state:
- `flake.lock` was already modified before this correction started
- this remediation should not stage/commit `flake.lock` unless explicitly requested

## Slices

### Slice 1 — Scope correction and module split

Status: completed

Changes made:
- moved `modules/features/desktop/nwg-shell.nix` to `modules/features/desktop/nwg-dock.nix`
- changed publisher to `flake.modules.homeManager.nwg-dock`
- removed `nwg-panel`, `nwg-clipman`, and their trial wrappers from the feature
- added separate `modules/features/desktop/vicinae.nix`
- wired `homeManager.nwg-dock` and `homeManager.vicinae` in `modules/hosts/predator.nix`
- updated `docs/for-agents/001-repo-map.md`

Validation run:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅ `"25.11"`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `git diff --check` ✅

Commit target:
- `refactor(desktop): keep only nwg dock and add vicinae trial`

### Slice 2 — Mutable dock style and autostart

Status: completed

Root cause fixed:
- old `nwg-dock-trial` used `pgrep -x nwg-dock-hyprland`, which cannot match process names longer than 15 chars
- old command passed an absolute CSS path to `-s`; `nwg-dock-hyprland` interpreted it relative to `~/.config/nwg-dock-hyprland`, producing a broken path

Changes made:
- moved style payload to `config/apps/nwg-dock/dock-catppuccin.css`
- provisioned copy-once to editable live path:
  - `~/.config/nwg-dock-hyprland/style.css`
- changed dock launch to use `-s style.css`
- added `systemd.user.services.nwg-dock-hyprland`
- bound service to `hyprland-session.target`
- added `nwg-dock-restart`
- changed `nwg-dock-trial` into a service restart/status helper
- added `nwg-dock-hyprland.service` to Hyprland session reset-failed cleanup

Validation run:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅ `"25.11"`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `git diff --check` ✅

Post-switch checks to run interactively:
- `systemctl --user status nwg-dock-hyprland.service`
- `test -w ~/.config/nwg-dock-hyprland/style.css`
- `nwg-dock-trial`
- `nwg-dock-restart`

Commit target:
- `feat(desktop): autostart nwg dock with mutable style`

### Slice 3 — Vicinae manual trial

Status: completed

Changes made:
- installed `pkgs.vicinae` through a separate HM feature
- did not autostart Vicinae
- did not replace Rofi keybinds

Validation run:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅ `"25.11"`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `git diff --check` ✅

Post-switch checks:
- `vicinae --help`
- optional manual server test:
  - `vicinae server --replace`
  - `vicinae toggle`

Commit target:
- included with Slice 1

## Final State

Implemented in repo. Runtime activation is pending an interactive switch because the agent environment cannot provide sudo credentials.

Final expected state after switch:
- only `nwg-dock-hyprland` remains from the NWG tools
- `nwg-panel` and `nwg-clipman` are removed from the managed package set
- dock autostarts through `nwg-dock-hyprland.service`
- dock CSS is editable live at `~/.config/nwg-dock-hyprland/style.css`
- `vicinae` is installed for manual testing, with Rofi still primary

Runtime correction after first user smoke:
- user reported dock appeared then disappeared and `vicinae toggle` failed with missing socket
- confirmed dock service was running, but `-d` autohide made it appear to die
- confirmed live style file was read-only and still default upstream CSS
- confirmed `vicinae.service` existed but was disabled/inactive, so `vicinae toggle` had no socket

Follow-up changes:
- changed dock service from autohide `-d` to resident `-r`
- made dock activation replace a read-only existing style with the repo template and chmod it writable
- added cleanup for the temporary live service drop-in created during emergency runtime repair
- added declarative `vicinae.service` bound to `hyprland-session.target`
- added `vicinae-toggle`, which starts the service before toggling if needed
- added `vicinae.service` to Hyprland session reset-failed cleanup

Live hotfix applied:
- replaced read-only live dock CSS with Catppuccin template and chmodded it writable
- created temporary live systemd drop-in `live-resident-fix.conf` to run dock with `-r` immediately
- restarted `nwg-dock-hyprland.service`; it is active in resident mode
- manually started `vicinae.service`
- `vicinae ping` ✅
- `vicinae toggle` command returned successfully ✅

Validation after follow-up changes:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
- `./scripts/run-validation-gates.sh structure` ✅
- `./scripts/check-repo-public-safety.sh` ✅
- `git diff --check` ✅

Remaining user commands:
- `nh os switch path:$HOME/nixos --out-link "$HOME/.cache/nh-result-predator"`
- `systemctl --user status nwg-dock-hyprland.service`
- `test -w ~/.config/nwg-dock-hyprland/style.css`
- `nwg-dock-trial`
- `vicinae-toggle`
