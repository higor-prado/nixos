# Predator Persist Subvolume Progress

## Status

In progress

## Related Plan

- [019-predator-persist-subvolume-plan.md](/home/higorprado/nixos/docs/for-agents/plans/019-predator-persist-subvolume-plan.md)

## Baseline

- `predator` system disk is encrypted Btrfs with `@root`, `@nix`, and `@log`
  only
- Docker state currently lives under `/var/lib/docker`
- rootful Podman storage defaults to `/var/lib/containers/storage`
- `/home` is already persistent on a separate Btrfs disk

## Slices

### Slice 1

- planned the persist-first migration for `predator`
- confirmed the relevant declarative knobs:
  - Docker daemon `data-root`
  - rootful containers storage `graphroot`
- confirmed that the live system also needs an explicit Btrfs subvolume
  creation/migration step, not only a `disko.nix` edit
- validation run:
  - `./scripts/check-docs-drift.sh`
- diff result:
  - none; docs-only slice
- commit:
  - pending

### Slice 2

- tested the declarative `@persist` mount too early
- confirmed from boot logs that the fatal failure was:
  - `persist.mount: fsconfig() failed: No such file or directory`
  - followed by `Dependency failed for Local File Systems`
  - and emergency mode
- conclusion:
  - the tracked `/persist` mount must not be activated before the live Btrfs
    subvolume exists and is verified
- reverted the uncommitted tracked `@persist`/Docker/Podman changes to restore
  branch safety before resuming the experiment

Validation:
- boot logs reviewed from `journalctl -b -1`
- identified `persist.mount` as the root cause of the disk failure

Diff result:
- declarative persist changes removed from the branch again

Commit:
- pending

### Slice 3

- reinstated the declarative persist groundwork after the DMS startup path was
  repaired
- tracked changes now include:
  - [disko.nix](/home/higorprado/nixos/hardware/predator/disko.nix):
    `@persist` mounted at `/persist`
  - [docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix):
    Docker `data-root = /persist/var/lib/docker`
  - [podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix):
    rootful `graphroot = /persist/var/lib/containers/storage`
- validation run:
  - `./scripts/run-validation-gates.sh structure`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.virtualisation.docker.daemon.settings`
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.virtualisation.containers.storage.settings`
- current live state:
  - `/var/lib/docker` size `0`
  - `/var/lib/containers/storage` size `0`
- conclusion:
  - the remaining live migration is low-risk because there is no rootful
    container state to preserve

Commit:
- pending

## Final State

- declarative groundwork is ready and validated
- live root migration step is still pending because it requires local `sudo`
  with a TTY
