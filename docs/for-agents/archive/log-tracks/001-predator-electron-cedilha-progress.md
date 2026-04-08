# Predator Electron Cedilha Progress

## Status

Completed

## Related Plan

- [001-predator-electron-cedilha-startup-fix.md](/home/higorprado/nixos/docs/for-agents/archive/plans/001-predator-electron-cedilha-startup-fix.md)

## Baseline

- Read the required operating docs in `docs/for-agents/000` through `006` and `999`.
- Confirmed the relevant tracked owners:
  - [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [modules/features/system/keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
  - [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)
  - [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  - [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)

- Live runtime facts captured on `2026-04-08`:
  - `~/.XCompose` exists and contains the tracked cedilha override.
  - user session environment contains `GTK_IM_MODULE=fcitx`, `QT_IM_MODULE=fcitx`, `SDL_IM_MODULE=fcitx`, and `XMODIFIERS=@im=fcitx`.
  - boot journal for `fcitx5-daemon.service` contains `Failed to open wayland connection`.
  - `niri.service` starts listening on `wayland-1` after that failure.
  - manual `systemctl --user restart fcitx5-daemon.service` removes the failure and yields a working Wayland/Xwayland UI path.

## Slices

### Slice 1

- No repo code changed yet.
- Root cause isolated to a startup race between `fcitx5-daemon.service` and Wayland socket readiness.
- Active plan written before implementation.

### Slice 2

- Updated [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix) to harden the generated `fcitx5-daemon.service`.
- Added a tracked `ExecStartPre` wait script for the Wayland socket.
- Added `After=niri.service`, `Restart=on-failure`, and `RestartSec=1` in the HM user-service override.
- Validation passed:
  - `./scripts/run-validation-gates.sh structure`
  - `nix flake metadata path:$PWD`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Slice 3

- Built the evaluated results into:
  - `/tmp/predator-fcitx5-home`
  - `/tmp/predator-fcitx5-system`
- Verified the generated unit directly from the store:
  - `/nix/store/048fvfigkd3qwkw5lzxh0vh6rznzz9qm-fcitx5-daemon.service/fcitx5-daemon.service`
  - contains `ExecStartPre=/nix/store/lz5g00k3n46gpx09f0xd6c9sz4y87dd6-fcitx5-wait-for-wayland-socket`
  - contains `Restart=on-failure`
  - contains `RestartSec=1`
  - contains `After=niri.service`
- Activated the evaluated Home Manager generation without reboot:
  - `/nix/store/br855h0chl83hs0b7kbcyyrlanwyss3q-home-manager-generation/activate`
- Confirmed the live unit now points at the new store path:
  - `systemctl --user cat fcitx5-daemon.service`
- Confirmed the live restart path succeeds:
  - `ExecStartPre ... status=0/SUCCESS`
  - `Created classicui for wayland display:`
  - `Using Wayland native input method protocol: 1`
  - no `Failed to open wayland connection` message appeared in the recent post-activation journal

### Slice 4

- Added a no-reboot transient-unit proof for the startup guard.
- Simulated the exact failure class:
  - unit starts with `XDG_RUNTIME_DIR` pointing to a temporary directory
  - `WAYLAND_DISPLAY` points to a socket path that does not exist yet
  - `ExecStartPre` uses the same wait script as the live `fcitx5-daemon.service`
- Observed before creating the socket:
  - `ActiveState=activating`
  - `SubState=start-pre`
  - `ExecMainPID=0`
  - started marker file absent
- Created a real temporary Unix socket with `nc -lU`.
- Observed after creating the socket:
  - `ActiveState=active`
  - `SubState=running`
  - `ExecMainPID` populated
  - started marker file present
- Journal proof from the transient run:
  - first attempt timed out waiting for the socket
  - systemd scheduled a restart
  - next attempt started successfully once the socket existed

### Slice 5

- Ran `nh os test path:$PWD --out-link /tmp/predator-fcitx5-test`.
- Build succeeded, but full system activation failed because `sudo` required an interactive TTY/password.
- Reused the built closure to extract:
  - `/nix/store/2n7rnnzqkwp6sl4j39rps2l5849x3r4b-fcitx5-wait-for-wayland-socket`
  - `/nix/store/5kx7ppcg48c675889pphn3h9wm3bd8rw-fcitx5-daemon.service`
  - `/nix/store/bmkqnhk0a6gx4xapihwhpwlyjynmpf1d-home-manager-generation`
- Activated the new HM generation directly in the current session.
- Confirmed the live unit now points to the final generated store paths above.

## Final State

- The startup hardening is implemented and active in the current session without reboot.
- There is now a no-reboot proof that the guard blocks service start until the socket exists and then allows startup once it appears.
- Immediate manual testing in Electron apps can be done now.
- Cold-login proof was intentionally left out of scope for this execution because the requested deliverable was a no-reboot test path.
