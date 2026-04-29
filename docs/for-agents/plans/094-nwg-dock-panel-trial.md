# NWG Dock Promotion and Vicinae Trial

## Goal

Keep only `nwg-dock-hyprland` from the NWG trial set, promote it from manual trial to an autostarted Hyprland dock, and keep its configuration editable in the live user environment. Add `vicinae` for manual launcher testing without replacing Rofi yet.

## Revised Scope

In scope:
- remove `nwg-panel` and `nwg-clipman` from the repo-managed trial package set
- rename the narrow feature owner from the broader NWG shell trial to `nwg-dock`
- install only `pkgs.nwg-dock-hyprland` for the dock feature
- provision the dock CSS as a mutable copy-once live file at `~/.config/nwg-dock-hyprland/style.css`
- start `nwg-dock-hyprland` automatically with the Hyprland user session
- provide a manual restart/debug wrapper for the dock
- install `pkgs.vicinae` in a separate narrow `vicinae` Home Manager feature for manual testing
- keep Rofi as the primary launcher until the user explicitly accepts Vicinae

Out of scope:
- keeping `nwg-panel`
- keeping `nwg-clipman`
- replacing current Rofi launcher keybinds with Vicinae
- adding Vicinae autostart by default
- making dock config immutable through `xdg.configFile` symlinks
- changing private files

## Root Cause of Failed Dock Trial

Observed error:

```text
pgrep: pattern that searches for process name longer than 15 characters will result in zero matches
WARN ~/.config/nwg-dock-hyprland/.../.config/nwg-shell/dock-catppuccin.css file not found
FATA Unable to create window ... No such file or directory
```

Causes:
- `pgrep -x nwg-dock-hyprland` cannot match names longer than 15 characters through the process-name path.
- `nwg-dock-hyprland -s` treats the style argument as a file under its own config directory, so passing an absolute path produced a broken concatenated path under `~/.config/nwg-dock-hyprland/`.
- The CSS was previously managed as an immutable Home Manager config-file link under `~/.config/nwg-shell/`, which conflicts with the user's requirement that app config files be editable live.

Fix direction:
- place the style template at `~/.config/nwg-dock-hyprland/style.css` via `mutable-copy.mkCopyOnce`
- launch the dock with `-s style.css`
- manage restart through systemd instead of `pgrep`/`pkill`

## Desired End State

- `nwg-dock-hyprland` starts automatically with `hyprland-session.target`.
- The dock uses `~/.config/nwg-dock-hyprland/style.css` and that file is editable live.
- Repo source template lives under `config/apps/nwg-dock/`.
- `nwg-dock-trial` no longer tries to launch via the broken absolute CSS path; it restarts/status-checks the dock service.
- `nwg-panel` and `nwg-clipman` are no longer installed by this feature.
- `vicinae` is installed for manual testing only.
- Waybar and Rofi remain the primary panel/launcher surfaces.

## Phases

### Phase 1: Scope correction and module split

Changes:
- rename `modules/features/desktop/nwg-shell.nix` to `modules/features/desktop/nwg-dock.nix`
- publish `flake.modules.homeManager.nwg-dock`
- remove `pkgs.nwg-panel`, `pkgs.nwg-clipman`, and their wrappers
- add `modules/features/desktop/vicinae.nix`
- wire `homeManager.nwg-dock` and `homeManager.vicinae` explicitly in `modules/hosts/predator.nix`
- update repo map

Validation:
- Home Manager build
- system build
- structure gate
- public safety gate

Commit target:
- `refactor(desktop): keep only nwg dock and add vicinae trial`

### Phase 2: Mutable dock style and autostart

Changes:
- move tracked style payload to `config/apps/nwg-dock/dock-catppuccin.css`
- provision it copy-once to `~/.config/nwg-dock-hyprland/style.css`
- add `systemd.user.services.nwg-dock-hyprland`
- bind service to `hyprland-session.target`
- launch with `-s style.css`
- add restart/status helper wrappers
- include the dock service in Hyprland session reset-failed cleanup

Validation:
- Home Manager build
- system build
- structure gate
- public safety gate
- after interactive switch:
  - `systemctl --user status nwg-dock-hyprland.service`
  - `test -w ~/.config/nwg-dock-hyprland/style.css`
  - `nwg-dock-trial`
  - `nwg-dock-restart`

Commit target:
- `feat(desktop): autostart nwg dock with mutable style`

### Phase 3: Vicinae manual testing

Changes:
- install `pkgs.vicinae` only
- do not autostart Vicinae
- do not replace Rofi keybinds yet

Validation after switch:
- `vicinae --help`
- manual test:
  - `vicinae server --replace`
  - `vicinae toggle`

Commit target:
- included with Phase 1 unless Vicinae requires extra config

## Validation Gates

Mandatory before final response:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
git diff --check
```

Run full `./scripts/run-validation-gates.sh` if the final diff is ready to commit.

## Notes

- The repo had an unrelated dirty `flake.lock` before this correction started; do not include it in dock/Vicinae commits unless explicitly requested.
- Config editability means use copy-once mutable provisioning for dock CSS, not Home Manager `xdg.configFile` symlinks.
- Vicinae is intentionally a separate feature owner so it can be removed or promoted independently from the dock.
