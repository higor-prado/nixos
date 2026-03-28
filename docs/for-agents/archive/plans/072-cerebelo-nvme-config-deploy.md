# Cerebelo: Correct Config and First NVMe Deploy

## Goal

Fix the cerebelo NixOS configuration in this repo so it correctly uses the
official `nixos-rk3588` vendor kernel and board modules, then perform the
first managed deploy to the Orange Pi 5 NVMe SSD. After this plan completes,
future `nixos-rebuild switch` on cerebelo will use the vendor kernel and will
update the bootloader directly.

## Scope

In scope:
- Correcting UUIDs in `hardware/cerebelo/storage-identifiers.nix` to match
  the installed system
- Rewriting `modules/features/system/rk3588-orangepi5.nix` to import
  `nixos-rk3588.nixosModules.boards.orangepi5.core` with the required
  `_module.args.rk3588` injection instead of a manual reimplementation
- Fixing `hardware/cerebelo/hardware-configuration.nix` to mount the FAT boot
  partition at `/boot` so `nixos-rebuild` writes the bootloader directly to FAT
- Removing stale `sdImage.*` overrides from `hardware/cerebelo/default.nix`
- First `nixos-rebuild boot` deploy followed by reboot validation

Out of scope:
- Plan 063 (WireGuard)
- New cerebelo features (GPU, display, NPU, etc.)
- Private override structure changes
- Cross-compilation setup on predator
- Cleanup of untracked helper scripts under `scripts/`

## Current State

- Branch: `cerebelo`, HEAD `1ecdecb`
- Vanilla `nixos-rk3588` image running on NVMe at `192.168.1.X` (`rk`/`rk3588`)
- Kernel: `6.1.115`, root UUID `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7`,
  BOOT UUID `2178-694E`, `/data` at sda1 UUID `e47efc1f-98d8-42ab-80e1-d0e29115e6e0`
- Unstaged from stash: `flake.nix`, `flake.lock` (adds `nixos-rk3588` input),
  `hardware/cerebelo/default.nix`, `hardware/cerebelo/hardware-configuration.nix`,
  `modules/hosts/cerebelo.nix`
- Untracked: `hardware/cerebelo/storage-identifiers.nix`,
  `modules/features/system/rk3588-orangepi5.nix`, scripts under `scripts/`,
  docs now moved to archive
- `flake.nix` already has the `nixos-rk3588` input at revision `2a1add82`
- `hardware/cerebelo/storage-identifiers.nix` has wrong UUIDs from a previous
  failed attempt (`913f90e9-...` root, `C424-DC5A` BOOT)
- `rk3588-orangepi5.nix` is a manual reimplementation that imports
  `sd-image-aarch64.nix` directly and creates `pkgsKernel` outside the module
  system; this caused the installed system to use the nixpkgs default kernel
  (6.18.19) instead of the vendor kernel (6.1.115)
- `hardware-configuration.nix` mounts FAT at `/boot/firmware` with the upstream
  default, meaning `nixos-rebuild` writes the bootloader to ext4 and the FAT
  (which U-Boot reads) becomes stale after each rebuild

## Desired End State

- `./scripts/run-validation-gates.sh cerebelo` passes
- `nix eval .#nixosConfigurations.cerebelo.config.boot.kernelPackages.kernel.version`
  returns `6.1.115`
- FAT (`nvme0n1p1`) is mounted at `/boot`; `nixos-rebuild` updates it directly
- Post-reboot: `uname -r` is `6.1.115`, `hostname` is `cerebelo`, SSH works as
  `higorprado`, `/boot` source is `nvme0n1p1`, `/` source is `nvme0n1p2`

## Phases

### Phase 0: Baseline

Confirm the current repo state before making any changes.

Validation:
- `git diff --stat HEAD` lists the unstaged files from the stash
- `nix eval .#nixosConfigurations.cerebelo.config.system.build.toplevel --apply toString 2>&1 | tail -5`
  (expected to fail or warn before fixes are applied)

### Phase 1: Fix Storage Identifiers

Targets:
- `hardware/cerebelo/storage-identifiers.nix`

Changes:
- `nvmeRootUuid`: `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7`
- `nvmeBootUuid`: `2178-694E`
- `dataUuid`: `e47efc1f-98d8-42ab-80e1-d0e29115e6e0`

Validation:
- `nix eval .#nixosConfigurations.cerebelo.config.fileSystems --apply builtins.attrNames --json`
  shows `/`, `/boot`, `/data` once Phase 3 is done; at this phase just confirm
  the file parses: `nix eval -f hardware/cerebelo/storage-identifiers.nix`

Diff expectation:
- Only UUID string values change in `storage-identifiers.nix`

Commit target:
- `fix(cerebelo): correct storage UUIDs to match installed NVMe`

### Phase 2: Rewrite `rk3588-orangepi5.nix`

Targets:
- `modules/features/system/rk3588-orangepi5.nix`

Changes:
- Import `inputs.nixos-rk3588.nixosModules.boards.orangepi5.core` (vendor kernel,
  DTB `rk3588s-orangepi-5.dtb`, Orange Pi firmware, base ARM initrd/filesystem config)
- Inject `_module.args.rk3588` with `nixpkgs = inputs.nixos-rk3588.inputs.nixpkgs`
  and `pkgsKernel = import <upstream-nixpkgs> { system = "aarch64-linux"; }` so
  the core module can resolve the vendor kernel package
- Inject `_module.args.nixos-generators = null` — required by `dtb-install.nix`
  in the module signature but unused when grub/systemd-boot are disabled
- Add the two DTB overlays from the official `sd-image/orangepi5.nix` directly:
  `orangepi5-sata-overlay` (disables sata0, enables pcie2x1l2 for NVMe) and
  `orangepi5-i2c-overlay`
- Enable `boot.loader.generic-extlinux-compatible`; disable grub
- Remove the `sd-image-aarch64.nix` import entirely — it is for SD image building,
  not for installed systems, and its cross-nixpkgs import caused kernel override
  to silently resolve to the nixpkgs default

Validation:
- `nix eval .#nixosConfigurations.cerebelo.config.boot.kernelPackages.kernel.version --raw`
  returns `6.1.115`
- `./scripts/run-validation-gates.sh cerebelo`

Diff expectation:
- `modules/features/system/rk3588-orangepi5.nix` substantially rewritten;
  smaller and simpler than the current version

Commit target:
- `refactor(cerebelo): use official rk3588 board module for vendor kernel`

### Phase 3: Fix `hardware-configuration.nix`

Targets:
- `hardware/cerebelo/hardware-configuration.nix`

Changes:
- `fileSystems."/boot"` → FAT, device by UUID `${storage.nvmeBootUuid}`,
  `fsType = "vfat"`, `options = [ "umask=0077" ]`
- Remove `fileSystems."/boot/firmware"` (was the upstream default for SD image
  builds; not correct for a deployed NVMe system where we want nixos-rebuild
  to write directly to FAT)
- Keep `fileSystems."/"` and `fileSystems."/data"` unchanged

Validation:
- `nix eval .#nixosConfigurations.cerebelo.config.fileSystems."/boot".fsType --raw`
  returns `vfat`
- `nix eval .#nixosConfigurations.cerebelo.config.fileSystems --apply builtins.attrNames --json`
  shows `/boot` present and `/boot/firmware` absent

Diff expectation:
- `/boot/firmware` entry removed; `/boot` entry added with FAT UUID

Commit target:
- `fix(cerebelo): mount FAT at /boot for direct extlinux writes on nixos-rebuild`

### Phase 4: Fix `hardware/cerebelo/default.nix`

Targets:
- `hardware/cerebelo/default.nix`

Changes:
- Remove `sdImage.rootPartitionUUID`, `sdImage.firmwarePartitionName`,
  `sdImage.firmwareSize` — these are SD image build options that do not exist
  in the module set after removing the `sd-image-aarch64.nix` import
- Keep `boot.kernelParams` with `lib.mkForce` (provides `root=UUID=...`,
  console params, cgroup flags)
- Keep `boot.consoleLogLevel = 7`

Validation:
- `./scripts/run-validation-gates.sh cerebelo`
- `nix eval .#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath --raw`
  succeeds without eval error

Diff expectation:
- `sdImage.*` lines removed; rest of `default.nix` unchanged

Commit target:
- `fix(cerebelo): remove stale sdImage options from hardware default`

### Phase 5: Deploy

Prerequisites:
- Phases 1–4 committed and passing
- cerebelo reachable at `192.168.1.X` as `rk`/`rk3588`

Steps:

1. Sync repo to cerebelo (exclude `.git` and untracked scripts):
   ```
   rsync -avz --exclude='.git' --exclude='scripts/' \
     . rk@192.168.1.X:~/nixos-config/
   ```

2. Sync private override (required for `higorprado` SSH key):
   ```
   rsync -avz private/hosts/cerebelo/ \
     rk@192.168.1.X:~/nixos-config/private/hosts/cerebelo/
   ```

3. On cerebelo — mount FAT at `/boot` before the rebuild:
   ```
   echo rk3588 | sudo -S mount /dev/disk/by-label/BOOT /boot
   findmnt /boot   # must show nvme0n1p1 vfat
   ```

4. On cerebelo — build and update bootloader only (does not touch running services):
   ```
   cd ~/nixos-config
   echo rk3588 | sudo -S nixos-rebuild boot --flake .#cerebelo
   ```
   Note: first build compiles the vendor kernel from source (~40 min on OPi5).

5. Verify FAT was updated — both of these must be true:
   - `cat /boot/extlinux/extlinux.conf` contains `k-Image` (vendor kernel
     derivation name, not `linux-*-Image`)
   - `cat /boot/extlinux/extlinux.conf` contains `root=UUID=14e19a7b-...`

6. Reboot:
   ```
   echo rk3588 | sudo -S reboot
   ```

Validation post-reboot:
- `ssh higorprado@192.168.1.X` succeeds (key from private override)
- `uname -r` returns `6.1.115`
- `hostname` returns `cerebelo`
- `findmnt -n -o SOURCE /` returns `/dev/nvme0n1p2`
- `findmnt -n -o SOURCE /boot` returns `/dev/nvme0n1p1`

Commit target:
- none (deploy phase produces no new repo changes)

## Risks

- Vendor kernel build (~40 min) requires internet access and sufficient disk space
  on cerebelo's NVMe
- If `_module.args.nixos-generators = null` causes an eval error due to strict
  type checking in dtb-install.nix, the alternative is to not import `boardModules.core`
  and instead inline its content directly (base.nix, kernel, DTB, firmware)
- After reboot, if the networking module differs from the vanilla image's dhcpcd
  setup, the IP may change; the private override should ensure `higorprado`
  SSH key is present before rebooting so recovery is possible
- The `/data` partition (sda1) has `nofail`; if the drive is absent the system
  still boots

## Definition of Done

- `./scripts/run-validation-gates.sh cerebelo` passes on predator
- `nix eval .#nixosConfigurations.cerebelo.config.boot.kernelPackages.kernel.version`
  returns `6.1.115`
- Post-reboot: SSH works as `higorprado`, kernel is `6.1.115`, root is
  `nvme0n1p2`, `/boot` is `nvme0n1p1`, hostname is `cerebelo`
- Plans 070 and 071 archived; this plan is the sole active cerebelo guide
