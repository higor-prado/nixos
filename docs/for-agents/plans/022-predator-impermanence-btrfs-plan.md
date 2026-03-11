# Predator Impermanence Btrfs Plan

## Goal

Migrate `predator` to an impermanence-style layout using:
- `impermanence` for the centralized persistence inventory
- Btrfs for the persistent storage layout
- Btrfs root reset/rollback instead of `tmpfs /`

The target outcome is:
- host persistence policy declared in one predator-scoped place
- no feature knowing about `/persist`
- persistent state explicitly listed through `environment.persistence`
- root reset on boot while keeping `@nix`, `@log`, `/home`, and `/persist`

## Architectural Rules

These rules are mandatory for whoever executes this plan.

1. Persistence ownership is host-scoped, not feature-scoped.
   - `docker.nix` and `podman.nix` must stay generic.
   - no feature may hardcode `/persist`.

2. `den` still owns feature composition.
   - the `predator` host decides that persistence/impermanence applies.
   - the persistence module is attached from `predator`, not from generic features.

3. `impermanence` centralizes what persists.
   - features continue to define services and packages
   - the predator persistence module defines the persisted files/directories

4. `aurelius` is out of scope.
   - nothing in this plan should leak predator-only persistence assumptions into shared features

## Scope

In scope:
- add the `impermanence` flake input/module
- revert the host-specific persistence coupling currently placed in shared features
- add a predator-scoped persistence module
- add a diagnostic script to surface new root-state candidates that may need persistence later
- centralize the persistence inventory with `environment.persistence."/persist"`
- prepare and implement Btrfs root reset/rollback for `@root`
- validate normal boot/reboot with the new model

Out of scope:
- `tmpfs /`
- `aurelius`
- redesigning unrelated desktop stacks
- long-term coredump retention strategy
- converting rootful Podman into a required workflow if it is not used

## Current State

### Current mount/layout state

- `/` -> `@root`
- `/nix` -> `@nix`
- `/var/log` -> `@log`
- `/persist` -> `@persist`
- `/home` -> separate persistent Btrfs disk
- `/boot` -> vfat ESP
- `/swap/swapfile` -> persistent swapfile with resume configured

### Current measured root size

After cleanup:
- `/` total: about `155 MiB`
- `/tmp`: `0`
- `/var`: about `69 MiB`
- `/usr`: about `85 MiB`
- `/etc`: negligible

### Current problem to correct first

The repo currently contains an architectural mistake:
- [docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix) sets `data-root = "/persist/var/lib/docker"`
- [podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix) sets rootful storage under `/persist`

That is wrong because:
- `/persist` is a predator host concern
- those feature modules are shared
- if another host enables Docker/Podman, it inherits a predator-only layout

This must be fixed before the impermanence rollout continues.

## Persistence Diagnosis

### Already persisted outside the root lifecycle

These do not need to be re-solved by impermanence:
- `/nix`
- `/var/log`
- `/home`
- `/boot`
- `/swap/swapfile`

### Must persist for correctness

These should be declared centrally in the predator persistence module and backed by `/persist`:

- `/etc/machine-id`
  - stable machine identity
- `/etc/ssh`
  - host SSH keys
- `/etc/NetworkManager/system-connections`
  - Wi-Fi and saved network profiles
- `/var/lib/bluetooth`
  - pairing and trust state
- `/var/lib/tailscale`
  - node identity/state
- `/var/lib/docker`
  - `predator` uses Docker and its rootful state must survive reboot
- `/var/lib/systemd/random-seed`
  - preserve entropy seed across boots

### Persist only if the workflow exists

- `/var/lib/containers/storage`
  - only if rootful Podman use matters
  - rootless Podman already persists under `/home`
- `/var/lib/systemd/coredump`
  - only if persistent coredumps are desired
  - if kept, prefer `@log`, not `@persist`

### Explicitly ephemeral

These should stay ephemeral unless a concrete reason appears:
- `/tmp`
- most of `/var/cache`
- `/var/lib/AccountsService`
- `/var/lib/NetworkManager`
- `/var/lib/upower`
- `/var/lib/fwupd`
- `/var/lib/nixos`
- `/var/lib/dms-greeter`
- `/var/lib/regreet`

## Why `impermanence` Is The Right Tool Here

For this repo, the value of `impermanence` is not `tmpfs`. It is:
- one centralized persistence inventory
- explicit ownership of persisted state
- less chance of scattering persistence decisions through features

That makes it a better fit than continuing with per-feature `/persist` settings.

## Target Architecture

### Shared features

- `docker.nix` only enables/configures Docker generically
- `podman.nix` only enables/configures Podman generically
- neither feature may know about `/persist`

### Predator host

`predator` owns:
- importing `impermanence`
- importing the predator persistence module
- exposing or documenting the persistence-candidate diagnostic workflow
- importing the Btrfs root-reset wiring

Recommended placement:
- `hardware/predator/impermanence.nix`
- `hardware/predator/root-reset.nix`
- `scripts/report-persistence-candidates.sh`

### Central persistence declaration

The predator persistence module should contain a single central block:
- `environment.persistence."/persist"`

and list:
- `directories = [ ... ]`
- `files = [ ... ]`

This is the inventory of persistent state for the host.

### Root reset model

Use Btrfs root reset/rollback, not `tmpfs`.

The intended model is:
- keep a clean base root subvolume or snapshot, e.g. `@root-blank`
- on boot, recreate/reset `@root` from that clean state
- mount the usual persistent subvolumes back in:
  - `/nix`
  - `/var/log`
  - `/persist`
  - `/home`
  - `/boot`

## Risks To Handle Explicitly

### Risk 1: Boot failure if `/persist` is missing

Already seen in practice:
- `persist.mount` failed
- `local-fs.target` failed
- emergency mode

Mitigation:
- never activate persistence wiring unless `@persist` exists live
- manual Btrfs mount verification remains mandatory before first activation

### Risk 2: Missing persistence inventory

This is the main impermanence risk.

Mitigation:
- start with a conservative first inventory
- prefer persisting one extra path over forgetting a critical path
- verify real services after each activation and reboot

### Risk 3: Hibernation/resume

`predator` has:
- `/swap/swapfile`
- `boot.resumeDevice`
- `resume_offset`

Changing root-reset behavior is not the same as changing swap, but hibernation must still be revalidated after the root-reset phase.

Mitigation:
- normal boot/reboot first
- hibernate/resume later as a dedicated compatibility slice

## Rollout Strategy

Do not jump directly to root reset.

Use this order:
1. fix the architectural mistake in shared features
2. add `impermanence` and the central persistence inventory
3. add the persistence-candidate diagnostic script
4. verify the persistence inventory with no root reset yet
5. add Btrfs root-reset wiring
6. test reboot
7. test hibernate/resume later

## Phases

### Phase 0: Baseline and safety

Goal:
- ensure the currently working state is committed and recoverable

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Status:
- already satisfied before this plan update

### Phase 1: Remove host persistence policy from shared features

Targets:
- [docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
- [podman.nix](/home/higorprado/nixos/modules/features/system/podman.nix)

Changes:
- remove `/persist`-specific storage paths from shared features
- restore generic Docker/Podman behavior in those feature modules

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `nix store diff-closures` against previous predator system

Expected diff:
- only removal of the misplaced host-specific storage paths from shared features

Commit target:
- `refactor: remove predator persistence policy from shared container features`

### Phase 2: Add `impermanence` and a predator-scoped persistence module

Targets:
- `flake.nix`
- `flake.lock`
- [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- [impermanence.nix](/home/higorprado/nixos/hardware/predator/impermanence.nix)

Changes:
- add the `impermanence` input
- import `impermanence.nixosModules.impermanence` for `predator`
- add a predator-scoped persistence module
- define the centralized inventory with `environment.persistence."/persist"`

Initial inventory must include:
- `/etc/machine-id`
- `/etc/ssh`
- `/etc/NetworkManager/system-connections`
- `/var/lib/bluetooth`
- `/var/lib/tailscale`
- `/var/lib/docker`
- `/var/lib/systemd/random-seed`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.environment.persistence`
- `nix store diff-closures` against previous predator system

Expected diff:
- persistence wiring only

Commit target:
- `refactor: add predator impermanence inventory`

### Phase 3: Add the persistence-candidate discovery script

Goal:
- provide a repeatable way to detect new non-persisted root-state paths after future changes

Targets:
- `scripts/report-persistence-candidates.sh`
- docs for its intended use

Behavior:
- inspect the current root filesystem
- ignore mounts already known to be persistent or intentionally separate, such as:
  - `/nix`
  - `/var/log`
  - `/persist`
  - `/home`
  - `/boot`
- surface likely stateful paths under `/etc`, `/var/lib`, and other root-owned locations
- be diagnostic only, not a failing gate

Validation:
- `bash scripts/report-persistence-candidates.sh`
- `bash scripts/check-changed-files-quality.sh`

Commit target:
- `feat: add persistence candidate diagnostic script`

### Phase 4: Live verify the persistence inventory without root reset

Goal:
- prove that the persistence map is correct before touching `@root`

Checks:
- `findmnt /persist`
- verify existence/permissions of persisted targets under `/persist`
- verify Docker still works
- verify Bluetooth, Tailscale, and NetworkManager state remain healthy after `nh os test`

Expected result:
- no change to root lifecycle yet
- only persistence inventory active

Commit target:
- progress log only

### Phase 5: Prepare Btrfs root reset design

Targets:
- [root-reset.nix](/home/higorprado/nixos/hardware/predator/root-reset.nix)
- possibly [disko.nix](/home/higorprado/nixos/hardware/predator/disko.nix) if mount semantics need adjustment

Changes:
- define the Btrfs root reset mechanism
- keep `@root` recoverable during rollout
- create or maintain a clean root baseline, e.g. `@root-blank`
- wire the reset logic in initrd/early boot

Design rule:
- do not destroy the last known-good `@root` until reboot verification succeeds

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- review generated initrd/boot logic
- `nix store diff-closures` against pre-reset system

Commit target:
- `refactor: add predator btrfs root reset wiring`

### Phase 6: Reboot verification

Goal:
- verify the new root lifecycle actually works

Checks after reboot:
- `findmnt /`
- `findmnt /persist`
- `findmnt /var/log`
- Docker health
- `systemctl --failed --no-pager`
- `systemctl --user --failed --no-pager`
- DMS/Niri/session sanity on `predator`

Expected result:
- root reset works
- persisted state survives
- ephemeral state is discarded

Commit target:
- progress log only

### Phase 7: Hibernate/resume compatibility

Goal:
- revalidate suspend-to-disk after the root-reset model is stable

Validation:
- explicit hibernate/resume test
- confirm swap/resume path still works

Commit target:
- `docs: record predator impermanence hibernate compatibility`

## Fallback

If any activation or reboot fails:

1. boot the last known-good generation
2. if needed, mount Btrfs top-level and inspect:
   - `@root`
   - `@root-blank`
   - `@persist`
   - `@log`
3. revert the last impermanence slice
4. do not continue to the next phase until the failing phase is understood

## Success Criteria

This project is done when all of these are true:

- shared features no longer know about `/persist`
- `predator` owns persistence policy in one central module
- `environment.persistence."/persist"` is the single inventory of persisted host state
- Btrfs root reset works on reboot
- Docker state survives reboot
- Bluetooth, Tailscale, NetworkManager, and SSH identity survive reboot
- no regression on `aurelius`
