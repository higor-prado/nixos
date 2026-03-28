# Cerebelo Upstream Bootstrap Contract

## Why This Note Exists

`cerebelo` failed repeated NVMe boots after local changes that treated Orange Pi
5 bootstrap as a generic nixpkgs `extlinux` host with a DTB override. This note
freezes the upstream contract before any further board changes.

## Primary Sources Read

Official upstream repo checked locally at `/tmp/gnull-nixos-rk3588`:
- `README.md`
- `U-Boot.md`
- `modules/boards/orangepi5.nix`
- `modules/sd-image/orangepi5.nix`
- `examples/demo/flake.nix`
- `examples/upstream-opi/README.md`
- `examples/upstream-opi/sdcard.nix`
- `Debug.md`

Live working SD baseline checked on `rk@192.168.1.X`:
- `/boot/extlinux/extlinux.conf`
- `/boot/nixos/*`
- `uname -a`
- `lsblk -o NAME,SIZE,FSTYPE,LABEL,UUID,MOUNTPOINTS`

## Frozen Findings

1. The working SD system is using the `nixos-rk3588` U-Boot shape, not the
   generic host shape I had been synthesizing locally.
   Evidence:
   - host name on the board is `orangepi5`
   - default user is `rk`
   - `/boot/extlinux/extlinux.conf` points at
     `nixos-system-orangepi5-sd-card-26.05.20251221.a653104`
   - the kernel on the live system is `6.1.115`
   - the DTB path is under a `device-tree-overlays` output

2. The official Orange Pi 5 board stack is split into two responsibilities.
   - `modules/boards/orangepi5.nix` owns vendor kernel, DTB, firmware, and
     board kernel parameters.
   - `modules/sd-image/orangepi5.nix` owns the U-Boot boot shape:
     - `boot.loader.generic-extlinux-compatible.enable = true`
     - root UUID kernel args
     - `/boot/firmware` FAT payload generation
     - Orange Pi 5 overlays such as NVMe enablement

3. The official deployment example for U-Boot imports the board `sd-image`
   module as part of the deployed configuration, not only while building an
   install image.
   Evidence:
   - `examples/demo/flake.nix` sets `bootloaderModule = boardModule.sd-image`
     when `bootType = "u-boot"`

4. The official repo also documents an upstream nixpkgs-only path for Orange Pi
   boards, but that is a separate configuration family.
   Evidence:
   - `README.md` explicitly points to `examples/upstream-opi/`
   - `examples/upstream-opi/` uses upstream kernel and upstream U-Boot packages
     such as `pkgs.ubootOrangePi5Plus`
   This means "upstream-only" is valid in principle, but it is not the same
   stack as the image currently booting `cerebelo` from microSD.

5. The local repo does not currently import either supported upstream family.
   Evidence:
   - [flake.nix](/home/higorprado/nixos/flake.nix) has no `nixos-rk3588` input
   - [modules/hosts/cerebelo.nix](/home/higorprado/nixos/modules/hosts/cerebelo.nix)
     imports only local host modules plus
     [hardware/cerebelo/default.nix](/home/higorprado/nixos/hardware/cerebelo/default.nix)
   - [hardware/cerebelo/default.nix](/home/higorprado/nixos/hardware/cerebelo/default.nix)
     hardcodes boot args but does not import the official Orange Pi 5 board
     ownership

## Invalidated Assumptions

- Invalid: a generic nixpkgs `extlinux` host plus `hardware.deviceTree.name`
  is enough for Orange Pi 5 bootstrap here.
- Invalid: matching only `extlinux.conf` text and root UUID is sufficient.
- Invalid: local `/boot` mirroring hacks are an acceptable substitute for the
  official board stack.

## Required Direction

The next implementation step must choose one supported upstream family and wire
`cerebelo` to it explicitly:
- either import `gnull/nixos-rk3588` Orange Pi 5 modules and keep using that
  vendor-kernel U-Boot stack
- or intentionally switch to the upstream nixpkgs-only Orange Pi path and build
  the host from that contract

Because the current working SD system already proves the first family on this
hardware, that is the safer recovery path.
