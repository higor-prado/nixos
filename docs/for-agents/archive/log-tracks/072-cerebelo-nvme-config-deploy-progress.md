# Cerebelo NVMe Config Deploy Progress

## Status

Completed

## Related Plan

- [072-cerebelo-nvme-config-deploy.md](/home/higorprado/nixos/docs/for-agents/plans/072-cerebelo-nvme-config-deploy.md)

## Baseline

- Branch: `cerebelo`
- Vanilla `nixos-rk3588` image running on NVMe at `192.168.1.X` (`rk`/`rk3588`)
- Kernel: `6.1.115`, root UUID `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7`, BOOT UUID `2178-694E`
- `storage-identifiers.nix` has wrong UUIDs from a previous failed attempt
- `rk3588-orangepi5.nix` is a manual reimplementation that causes the wrong kernel
- `hardware-configuration.nix` mounts FAT at `/boot/firmware` (stale after rebuild)
- `hardware/cerebelo/default.nix` has stale `sdImage.*` options

## Slices

### Phase 1: Fix Storage Identifiers

- Changed `nvmeRootUuid` to `14e19a7b-0ae0-484d-9d54-43bd6fdc20c7`
- Changed `nvmeBootUuid` to `2178-694E`
- `dataUuid` unchanged (`e47efc1f-98d8-42ab-80e1-d0e29115e6e0`)
- Validation: file parses without error
- Commit: `fix(cerebelo): correct storage UUIDs to match installed NVMe`

### Phase 2: Rewrite rk3588-orangepi5.nix

- Replaced manual reimplementation with import of `boardModules.core`
- Injected `_module.args.rk3588` and `_module.args.nixos-generators = null`
- Copied DTB overlays from sd-image module (sata + i2c)
- Enabled `generic-extlinux-compatible`, disabled grub
- Removed `sd-image-aarch64.nix` import entirely
- Validation: `nix eval .#nixosConfigurations.cerebelo.config.boot.kernelPackages.kernel.version --raw` returns `6.1.115`
- Commit: `refactor(cerebelo): use official rk3588 board module for vendor kernel`

### Phase 3: Fix hardware-configuration.nix

- Changed `fileSystems."/boot/firmware"` → `fileSystems."/boot"` with vfat UUID
- Commit: `fix(cerebelo): mount FAT at /boot for direct extlinux writes on nixos-rebuild`

### Phase 4: Fix default.nix

- Removed `sdImage.rootPartitionUUID`, `sdImage.firmwarePartitionName`, `sdImage.firmwareSize`
- Validation: `nix eval .#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath --raw` succeeds
- Commit: `fix(cerebelo): remove stale sdImage options from hardware default`

### Phase 5: Deploy

- Status: pending phases 1–4

## Final State

- Pending
