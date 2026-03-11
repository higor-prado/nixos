# Predator Persist Subvolume Plan

## Goal

Create a dedicated persistent Btrfs subvolume on `predator` for heavyweight
container state, move Docker there, and configure rootful Podman storage to use
the same persistent area. This is Phase 1 groundwork for future
impermanence-style root experimentation on `predator`, not a full
impermanence rollout.

## Scope

In scope:
- `predator` only
- declarative `@persist` subvolume/mount in tracked config
- rootful Docker state relocation
- rootful Podman storage relocation
- live migration steps for the already-installed machine
- validation, rollback notes, and closure diffs

Out of scope:
- `aurelius`
- ephemeral root / root reset logic
- importing the `impermanence` module
- broad persistence policy for every service on the host
- rootless Podman data under `$HOME`

## Current State

- `predator` root disk is encrypted Btrfs in
  [hardware/predator/disko.nix](/home/higorprado/nixos/hardware/predator/disko.nix)
  with subvolumes:
  - `@root` mounted at `/`
  - `@nix` mounted at `/nix`
  - `@log` mounted at `/var/log`
- `/home` is already on a separate persistent Btrfs disk/subvolume.
- Docker is enabled in
  [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
  and currently uses default state under `/var/lib/docker`.
- Podman is enabled in
  [modules/features/system/podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix).
- NixOS container storage defaults put rootful Podman storage at
  `/var/lib/containers/storage`.
- Adding a subvolume to `disko.nix` does not create it on the already-installed
  machine; the live Btrfs subvolume must also be created and data migrated.
- A previous `nh os test` on this branch coincided with a broken desktop login
  path (`dms`/`dms-awww`). The persist work must not continue until the desktop
  startup path is repaired independently.

## Desired End State

- `predator` has a tracked `@persist` subvolume mounted at `/persist`.
- Docker stores state at `/persist/var/lib/docker`.
- Rootful Podman stores state at `/persist/var/lib/containers/storage`.
- The machine keeps working after switch/reboot.
- The repo is ready for later impermanence work without having Docker/Podman
  tangled in `@root`.

## Phases

### Phase 0: Freeze and repair prerequisites

Targets:
- live `predator` system
- DMS startup track

Changes:
- do not apply any more persist/disk activation changes until DMS startup is
  fixed
- treat the desktop startup repair as a hard prerequisite for more live disk
  testing
- keep the declarative `@persist` edits uncommitted until the host is stable

Validation:
- `./scripts/check-docs-drift.sh`

Diff expectation:
- no closure changes

Commit target:
- none

### Phase 1: Declarative Persist Mount

Targets:
- [hardware/predator/disko.nix](/home/higorprado/nixos/hardware/predator/disko.nix)

Changes:
- add `@persist` to the encrypted system Btrfs layout
- mount it at `/persist`
- use the same conservative mount options as the other root-disk subvolumes

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- system diff limited to mount/unit/config changes expected from adding `/persist`
- HM diff empty

Commit target:
- `refactor: add predator persist subvolume`

### Phase 2: Declarative Docker/Podman Relocation

Targets:
- [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
- [modules/features/system/podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix)

Changes:
- set Docker daemon `data-root` to `/persist/var/lib/docker`
- set rootful containers storage `graphroot` to
  `/persist/var/lib/containers/storage`
- keep Podman `runroot` under `/run/containers/storage`
- do not touch rootless Podman under `$HOME`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.virtualisation.containers.storage.settings`

Diff expectation:
- system diff limited to container runtime config
- HM diff empty

Commit target:
- `refactor: relocate predator container state to persist`

### Phase 3: Live subvolume creation and mount verification on Predator

Targets:
- live `predator` system only

Changes:
- create the `@persist` Btrfs subvolume on the current root disk
- create required directories under `/persist`
- verify the mount exists and is stable before touching container data
- only after mount verification, stop Docker and copy existing Docker state
- optionally initialize rootful Podman storage directory

Validation:
- `findmnt /persist`
- `mount | grep ' /persist '`
- `test -d /persist/var/lib/docker`
- `test -d /persist/var/lib/containers/storage`

Diff expectation:
- no configuration activation yet; filesystem prep only

Commit target:
- no new tracked code if Phase 1/2 were already committed; record the live
  migration in the progress log

### Phase 4: Activation on Predator

Targets:
- live `predator` system only

Changes:
- run `nh os test` only after Phase 3 is green
- verify desktop login path, `/persist`, Docker, and Podman together

Validation:
- `findmnt /persist`
- `systemctl --failed --no-pager`
- `systemctl --user --failed --no-pager`
- `docker info | grep -F "Docker Root Dir"`
- `podman info --format json`

Diff expectation:
- runtime state preserved for Docker after migration
- no regression in desktop/runtime health

Commit target:
- record activation outcome in the progress log

### Phase 5: Reboot Verification

Targets:
- live `predator` system only

Changes:
- reboot and confirm mounts/services come back cleanly

Validation:
- `findmnt /persist`
- `docker info | grep -F "Docker Root Dir"`
- `podman info --format json`
- `systemctl --failed --no-pager`

Diff expectation:
- none; this is post-change verification

Commit target:
- `docs: record predator persist migration verification`

## Risks

- continuing the persist work before the DMS startup path is repaired will mix
  two unrelated failures and make recovery/debugging worse
- forgetting to create `@persist` live before switching can leave `/persist`
  unmounted or break activation expectations
- moving Docker state while the daemon is active can corrupt or desync data
- rootful Podman storage relocation helps future impermanence work, but may be
  irrelevant if actual usage is rootless-only
- if `/persist` is mounted but the migration copy is incomplete, Docker may come
  up with an empty state directory

## Definition of Done

- `@persist` exists in tracked `disko.nix`
- `predator` evaluates and builds cleanly
- Docker and rootful Podman point at `/persist`
- live `predator` has `/persist` mounted after switch/reboot
- Docker state is preserved after the migration
- progress log records the migration and verification results
