# Predator Impermanence Btrfs Progress

## Status

Planned

## Related Plan

- [022-predator-impermanence-btrfs-plan.md](/home/higorprado/nixos/docs/for-agents/plans/022-predator-impermanence-btrfs-plan.md)

## Baseline

- `predator` already has:
  - `/nix` on `@nix`
  - `/var/log` on `@log`
  - `/persist` on `@persist`
  - `/home` on a separate persistent disk
  - zram plus disk swapfile fallback
- measured current `/` usage after cleanup is about `155 MiB`
- the current active direction is Btrfs root reset, not `tmpfs /`

## Slices

### Slice 1

- the previous tmpfs-oriented plan was superseded
- the active plan now requires:
  - removing predator-only `/persist` policy from shared container features
  - adding `impermanence` as the centralized persistence inventory
  - adding a diagnostic script to surface future persistence candidates under `/`
  - keeping persistence host-scoped under `predator`
  - implementing Btrfs root reset instead of `tmpfs /`

### Slice 2

- removed `/persist` coupling from shared features:
  - [docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
  - [podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix)
- added `impermanence` input to [flake.nix](/home/higorprado/nixos/flake.nix)
- imported `impermanence.nixosModules.impermanence` only for `predator`
- added predator-scoped persistence module:
  - [impermanence.nix](/home/higorprado/nixos/hardware/predator/impermanence.nix)
- extracted the central inventory to:
  - [_persistence-inventory.nix](/home/higorprado/nixos/hardware/predator/_persistence-inventory.nix)
- added diagnostic helper:
  - [report-persistence-candidates.sh](/home/higorprado/nixos/scripts/report-persistence-candidates.sh)

### Slice 3

- validation findings during implementation:
  - the first inventory missed `/var/lib/nixos`
  - `impermanence` warned that missing `/var/lib/nixos` would allow UID/GID reassignment on reboot
  - the inventory was corrected to include `/var/lib/nixos`
- structure validation passed after documenting the new shared auxiliary script
- the persistence-candidate script now reads the dedicated inventory file instead of evaluating the full `impermanence` config attrset

### Slice 4

- `predator` system and HM builds completed
- `nix store diff-closures` for the system slice showed the expected new impermanence units and persistence helpers:
  - `persistence-create`
  - `persistence-mount`
  - `persistence-persist`
  - bind/unbind helpers for machine-id, SSH host keys, and random-seed
  - mount units for:
    - `/etc/NetworkManager/system-connections`
    - `/var/lib/bluetooth`
    - `/var/lib/docker`
    - `/var/lib/containers/storage`
    - `/var/lib/tailscale`
- the closure diff also contained unrelated package bumps already present in `flake.lock`:
  - `codex`
  - `dms-shell`
  - `kilocode-cli`
- `aurelius` structural validation stayed green after removing the misplaced `/persist` coupling from shared features

### Pending

- Btrfs root-reset wiring is implemented locally but not committed yet
- reboot validation found the `root-reset` service did not actually run:
  - `journalctl -b` showed `root-reset.service` failed with `mount: command not found`
  - `@old-roots` was not created on the Btrfs top level
- first-activation persistence migration also exposed a design issue:
  - keeping bootstrap seeding in activation scripts is effective as a one-off rescue tool
  - but it is the wrong steady-state design for this repo
- the live module is therefore being refactored back to the clean upstream pattern:
  - declarative `environment.persistence`
  - Btrfs root reset
  - manual/documented pre-seeding for newly added persisted paths
- the reason the root-reset implementation looks more explicit than the upstream
  README snippet is now documented:
  - upstream uses `boot.initrd.postResumeCommands`
  - `predator` uses `boot.initrd.systemd.enable = true`
  - NixOS rejects `postResumeCommands` in systemd stage-1, so the reset must be
    implemented as `boot.initrd.systemd.services.root-reset`
  - the first unit failed at boot with `mount: command not found`
  - the refined fix is to use `boot.initrd.systemd.initrdBin`, which is the
    proper NixOS stage-1 pattern for bringing binaries into initrd systemd
    services

## Final State

- execution in progress
- safe pre-root-reset slices are implemented
- root-reset was attempted but failed in initrd due to missing absolute binary paths
- next slice is:
  - fix `root-reset`
  - remove permanent bootstrap migration logic
  - re-test reboot

### Password state finding

- upstream `impermanence` does not document or special-case `/etc/shadow`
- trying to persist `/etc/shadow` on `predator` broke activation in `update-users-groups.pl` with:
  - `rename: Device or resource busy`
- the steady-state fix is:
  - keep `/etc/shadow` out of the persistence inventory
  - source the local password via an untracked private override using `hashedPasswordFile`
  - store the actual hash in `/persist/secrets/higorprado-password-hash`
