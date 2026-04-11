# Predator Gaming Return Progress

## Status

In progress

## Related Plan

- [075-predator-gaming-return.md](/home/higorprado/nixos/docs/for-agents/plans/075-predator-gaming-return.md)

## Baseline

- Active plan created at
  [075-predator-gaming-return.md](/home/higorprado/nixos/docs/for-agents/plans/075-predator-gaming-return.md).
- Historical review concluded:
  - keep the current `predator` host performance and NVIDIA baseline
  - do not restore previously rejected global governor/swappiness experiments
  - restore gaming in small slices, starting with a minimal Steam-first path
- Pre-slice validation already completed:
  - `./scripts/check-docs-drift.sh` -> ok
  - `./scripts/run-validation-gates.sh structure` -> ok
- Working tree note:
  - `flake.lock` was already modified before this slice and remains untouched

## Slices

### Slice 1

- created a new shared gaming owner at
  [gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
- first restored scope is intentionally narrow:
  - NixOS: Steam, Protontricks, GameMode
  - Home Manager: MangoHud
- wired the feature back into the `predator` desktop composition
- validation:
  - `nix flake metadata` -> ok
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion` -> `"25.11"`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` -> `"25.11"`
  - `./scripts/run-validation-gates.sh structure` -> ok
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` -> ok
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` -> ok
- diff result:
  - `predator` now evaluates and builds with a minimal Steam-first gaming path again
  - HM closure gained `mangohud`
  - system closure gained Steam, Protontricks, and GameMode
- commit:
  - pending

### Slice 2

- restored narrow Steam-specific input-method compatibility in
  [gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
- restored only the already-proven Steam bridge:
  - `GTK_IM_MODULE=fcitx`
  - `SDL_IM_MODULE=fcitx`
  - `XMODIFIERS=@im=fcitx`
  - `programs.steam.extraPackages = [ pkgs.fcitx5-gtk ]`
- intentionally did not restore `ntsync`, NVAPI, NGX updater, or
  `VKD3D_CONFIG` in the same slice
- validation:
  - `./scripts/run-validation-gates.sh structure` -> ok
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` -> ok
- diff result:
  - Steam now carries the narrow `fcitx` bridge again without changing the
    wider session/input-method ownership model
- commit:
  - pending

### Slice 3

- restored the low-risk Proton/NVIDIA layer in
  [gaming.nix](/home/higorprado/nixos/modules/features/desktop/gaming.nix)
- added:
  - `boot.kernelModules = [ "ntsync" ]`
  - `PROTON_USE_NTSYNC=1`
  - `PROTON_ENABLE_NVAPI=1`
  - `PROTON_ENABLE_NGX_UPDATER=1`
- intentionally still did not restore `VKD3D_CONFIG=no_upload_hvv`, because
  that was justified mainly by the old Cyberpunk-specific 8GB VRAM path
- validation:
  - `./scripts/run-validation-gates.sh structure` -> ok
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` -> ok
- diff result:
  - Steam now carries the restored low-risk Proton/NVIDIA path
  - the evaluated system now also includes `systemd-modules-load` changes for
    the `ntsync` kernel module
- commit:
  - pending

### Slice 4

- verified live post-switch state on `predator`
- runtime checks confirmed:
  - `ntsync` is loaded in `/proc/modules`
  - `/run/current-system/sw/bin/steam` resolves to the active Steam wrapper
  - `/run/current-system/sw/bin/mangohud` exists in the active system path
  - `home-manager-higorprado.service` is present and active in system scope
- sandbox note:
  - `gamemoderun /run/current-system/sw/bin/true` from the Codex sandbox hit
    `Failed to connect to socket /run/user/1002/bus: Operation not permitted`
  - that check is limited by sandbox access to the live user bus, so it is not
    sufficient to classify GameMode as broken on the host
- validation:
  - post-switch host checks only
- diff result:
  - live host state matches the intended tracked gaming return closely enough to
    move the next proof step to interactive desktop runtime verification
- commit:
  - pending

## Final State

- Open. Minimal Steam-first gaming path and narrow Steam input compatibility are
  restored in tracked config.
- The tracked gaming return now includes:
  - Steam
  - Protontricks
  - GameMode
  - MangoHud
  - narrow Steam `fcitx` compatibility
  - `ntsync`, NVAPI, and NGX updater in the Steam path
- Runtime verification on `predator` is still the next real proof step.
