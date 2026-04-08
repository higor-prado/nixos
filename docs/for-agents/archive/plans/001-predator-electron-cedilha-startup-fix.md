# Predator Electron Cedilha Startup Fix

## Goal

Make `ç` / `Ç` deterministic again in Electron apps on `predator` after reboot by fixing the real session-startup fault in the input-method stack, then harden the ownership and validation story so the regression does not return.

## Scope

In scope:
- `predator` desktop session startup ordering for `fcitx5`
- runtime path used by Electron apps such as VS Code and Obsidian
- tracked ownership in the `keyboard`, `fcitx5`, and desktop-composition owners
- proof-oriented validation after rebuild and after cold reboot

Out of scope:
- changing the keyboard layout away from `us/alt-intl`
- changing the repo locale policy away from `LANG=en_US.UTF-8` plus `LC_CTYPE=pt_BR.UTF-8`
- broad app-specific hacks for individual Electron apps unless the startup fix is proven insufficient
- private overrides

## Current State

- `predator` imports:
  - [modules/features/system/keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
  - [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)
  - [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  - [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
  through the concrete host owner [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix).

- Cedilha fallback already exists in the keyboard owner:
  - [modules/features/system/keyboard.nix](/home/higorprado/nixos/modules/features/system/keyboard.nix)
    writes `~/.XCompose` with:
    - `<dead_acute> <c> : "ç" ccedilla`
    - `<dead_acute> <C> : "Ç" Ccedilla`

- The live session baseline collected on `2026-04-08` shows:
  - `~/.XCompose` exists and matches tracked content.
  - `systemctl --user show-environment` contains:
    - `LANG=en_US.UTF-8`
    - `LC_CTYPE=pt_BR.UTF-8`
    - `GTK_IM_MODULE=fcitx`
    - `QT_IM_MODULE=fcitx`
    - `SDL_IM_MODULE=fcitx`
    - `XMODIFIERS=@im=fcitx`
    - `WAYLAND_DISPLAY=wayland-1`
    - `DISPLAY=:0`

- The boot-time `fcitx5` journal captured the real failure:
  - `2026-04-08 13:33:49`: `Failed to open wayland connection`
  - `2026-04-08 13:33:50`: `niri` started listening on `wayland-1`

- A manual runtime proof was performed:
  - `systemctl --user restart fcitx5-daemon.service`
  - after restart, the journal no longer showed the failure and instead showed:
    - `Created classicui for x11 display::0`
    - `Created classicui for wayland display:`

- This isolates the current failure to startup timing:
  - `fcitx5-daemon.service` can start before the Wayland socket is actually available
  - when that happens, Electron apps lose the Wayland IM path after reboot

- There is additional structural fragility:
  - [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
    still carries IM-related environment
  - that file is provisioned copy-once via
    [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  - copy-once desktop files are a known drift risk in this repo

## Desired End State

- `fcitx5` reaches a working Wayland frontend automatically on every cold login
- boot-time journal contains no `Failed to open wayland connection`
- `ç` / `Ç` works in:
  - kitty
  - VS Code
  - Obsidian
- the startup guarantee is owned in the correct tracked module instead of relying on manual restarts
- IM-critical session behavior is declarative and auditable, not hidden in mutable copy-once drift

## Phases

### Phase 0: Freeze Baseline

Validation:
- `systemctl --user show-environment | rg '^(LANG|LC_CTYPE|GTK_IM_MODULE|QT_IM_MODULE|SDL_IM_MODULE|XMODIFIERS|WAYLAND_DISPLAY|DISPLAY)='`
- `journalctl --user -u fcitx5-daemon.service -b --no-pager | tail -n 120`
- `systemctl --user status fcitx5-daemon.service --no-pager`
- `systemctl --user status niri.service --no-pager`

Diff expectation:
- no repo diff

Commit target:
- none

### Phase 1: Move the Fix Into the Fcitx5 Owner

Targets:
- [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)

Changes:
- add a Home Manager override for `systemd.user.services.fcitx5-daemon`
- make startup wait for the real Wayland socket instead of trusting only `graphical-session.target`
- add bounded retry behavior so a transient race self-heals after login
- keep ownership in the `fcitx5` owner; do not scatter the fix into host hardware or private files

Implementation direction:
- use `ExecStartPre` to wait for `${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY}` or a stable equivalent
- if the generated upstream unit shape makes `ExecStartPre` awkward, replace the generated unit in the same owner with an explicit HM user-service definition that preserves the same package and lifecycle semantics
- add `Restart=on-failure`
- add `RestartSec=1`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- evaluated HM output now contains a hardened `fcitx5-daemon.service`
- no changes to keyboard layout or locale semantics

Commit target:
- `fix(input): harden fcitx5 startup against wayland race`

### Phase 2: Remove Input-Critical Drift From Copy-Once Desktop Config

Targets:
- [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
- [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
- possibly [modules/features/desktop/fcitx5.nix](/home/higorprado/nixos/modules/features/desktop/fcitx5.nix)

Changes:
- audit which IM/session exports are still duplicated in `custom.kdl`
- move IM-critical exports out of copy-once compositor config if they are already owned or should be owned by `fcitx5`
- leave compositor-specific behavior in `custom.kdl`
- keep the runtime story single-owner and deterministic

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- inspect the evaluated HM files for final ownership shape

Diff expectation:
- less duplicated IM policy
- no loss of needed session variables

Commit target:
- `refactor(input): remove copy-once im drift from desktop overlay`

### Phase 3: Runtime Proof After Rebuild

Targets:
- live `predator` session

Changes:
- apply the rebuilt configuration
- test without any manual `fcitx5` restart during login

Validation:
- `journalctl --user -u fcitx5-daemon.service -b --no-pager | rg 'Failed to open wayland connection'`
- `systemctl --user status fcitx5-daemon.service --no-pager`
- `systemctl --user show-environment | rg '^(GTK_IM_MODULE|QT_IM_MODULE|SDL_IM_MODULE|XMODIFIERS|WAYLAND_DISPLAY|DISPLAY)='`
- manual text-entry proof in:
  - kitty
  - VS Code
  - Obsidian

Diff expectation:
- zero boot-time Wayland-connect failure
- cedilha works before any manual intervention

Commit target:
- none

### Phase 4: Cold-Reboot Proof

Targets:
- live `predator` session after full reboot

Changes:
- cold reboot
- fresh login
- re-run the runtime checks from Phase 3

Validation:
- `journalctl --user -u fcitx5-daemon.service -b --no-pager | rg 'Failed to open wayland connection'` returns no match
- manual text-entry proof again in:
  - kitty
  - VS Code
  - Obsidian
- optional:
  - `nix store diff-closures /run/current-system ./result` if a local result symlink is produced during build/switch

Diff expectation:
- issue remains fixed across reboot, not only across in-session restarts

Commit target:
- none

### Phase 5: Final Documentation and Guardrails

Targets:
- [docs/for-agents/999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md)
- this plan
- matching progress log if execution proceeds

Changes:
- record the startup-race lesson in the durable lessons doc
- record the final verification commands and rollback path
- archive the plan when execution is complete

Validation:
- `./scripts/check-docs-drift.sh`

Diff expectation:
- repo docs explain the real failure mode and the proof path

Commit target:
- `docs(input): record fcitx wayland startup proof`

## Risks

1. Waiting on the wrong socket path can create a false sense of safety.
   Mitigation:
   - use the live session evidence from `WAYLAND_DISPLAY`
   - confirm the evaluated service really starts after the socket exists

2. Overriding the generated Home Manager unit incorrectly can break `fcitx5` entirely.
   Mitigation:
   - inspect the generated upstream unit first
   - keep the override as small as possible

3. Removing IM variables from `custom.kdl` too early could regress app behavior.
   Mitigation:
   - do it only after the owner shape is explicit in `fcitx5.nix`
   - validate with real Electron apps after every slice

4. Some Electron package may still need an app-specific compatibility flag even after startup is fixed.
   Mitigation:
   - only add app-specific handling if the generic startup fix is proven insufficient by runtime evidence

## Definition of Done

- boot-time `fcitx5` journal no longer shows `Failed to open wayland connection`
- `fcitx5-daemon.service` starts in a working state without manual restart
- `ç` / `Ç` works in kitty, VS Code, and Obsidian after a cold reboot
- startup ownership is auditable in the correct tracked module
- copy-once compositor config no longer carries critical IM policy unnecessarily
- the verification path is written down in tracked docs
