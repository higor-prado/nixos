# Multiple Hosts

## How hosts are declared

Each tracked host has:
- `hardware/<name>/default.nix`
- `modules/hosts/<name>.nix`

`modules/hosts/<name>.nix` declares one concrete dendritic configuration that
composes published feature modules and imports hardware config.

## Adding a new host

Use the skeleton script:

```bash
scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-experience]
```

Then adjust the generated `modules/hosts/<name>.nix` imports and hardware files
as needed.

See [workflow: add a host](workflows/103-add-host.md).

## Current tracked hosts

- predator, aurelius, and cerebelo are the tracked live hosts.
- new host onboarding is handled by the generator and its fixture tests, not by
  keeping tracked example hosts in the live configuration surface.

## predator

Laptop workstation. Acer Predator with NVIDIA RTX 4060 Max-Q.
Currently runs Hyprland compositor (standalone composition). Full home-manager config.

## aurelius

Remote server. Minimal NixOS, SSH access, deployed from predator via `nh`.


## cerebelo

Orange Pi 5 (RK3588S), headless server. Booted from NVMe via extlinux.
Uses the nixos-rk3588 upstream board stack. Deployed from predator via `nh`.