# Aurelius Runtime, Security, and Docs Reconciliation Progress

## Status

In progress

## Related Plan

- [062-aurelius-reconcile-runtime-security-and-docs.md](/home/higorprado/nixos/docs/for-agents/plans/062-aurelius-reconcile-runtime-security-and-docs.md)

## Baseline

- Review found three concrete problems:
  - Attic owner drift into file-sourced shell glue
  - tracked docs/examples no longer matching private runtime wiring
  - private `sudo` surface on `aurelius` broader than necessary

## Slices

### Slice 1

- Reverted the mistaken custom option surface from:
  - [attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)
  - [attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
  - [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix)
- Re-aligned the real private overrides back to the repo-native direct shape:
  - `private/hosts/aurelius/services.nix`
  - `private/hosts/predator/services.nix`
- Kept the Attic publisher hardening while restoring the direct contract:
  - added explicit tmpfiles for `/var/lib/attic-publisher`
  - removed silent `|| true` swallowing and replaced it with explicit stderr logging

### Slice 2

- Re-aligned tracked examples and human docs with the actual runtime contract:
  - [services.nix.example](/home/higorprado/nixos/private/hosts/aurelius/services.nix.example)
  - [services.nix.example](/home/higorprado/nixos/private/hosts/predator/services.nix.example)
  - [105-private-overrides.md](/home/higorprado/nixos/docs/for-humans/workflows/105-private-overrides.md)
  - [107-aurelius-service-bootstrap.md](/home/higorprado/nixos/docs/for-humans/workflows/107-aurelius-service-bootstrap.md)
  - [056-aurelius-github-runner-progress.md](/home/higorprado/nixos/docs/for-agents/current/056-aurelius-github-runner-progress.md)

### Slice 3

- Narrowed the private `sudo` surface on `aurelius` by removing unnecessary
  `NOPASSWD` entries for:
  - `nixos-rebuild`
  - `nix-env`
  - `nh`
- Kept only the commands still needed for the remote deploy path:
  - `nix`
  - `switch-to-configuration`

### Slice 4

- Revalidated the narrowed private `sudo` surface on `aurelius` directly:
  - `sudo --non-interactive /run/current-system/sw/bin/nix --version`
  - `sudo --non-interactive /nix/var/nix/profiles/system/bin/switch-to-configuration test`
- The remote deploy path also got past the old Tailscale SSH interactive gate
  and into real closure copy on the host.

## Current State

- The first attempted fix was wrong because it reintroduced custom option
  surfaces that this repo does not use for this kind of feature wiring.
- The correct target shape is:
  - feature import is the condition
  - tracked feature owns only stable payload
  - private overrides inject concrete facts directly into the real lower-level
    NixOS options
- The private `sudo` surface on `aurelius` is still narrower while covering the
  proven remote operator path.
