# Aurelius Runtime, Security, and Docs Reconciliation Progress

## Status

Complete

## Related Plan

- [062-aurelius-reconcile-runtime-security-and-docs.md](/home/higorprado/nixos/docs/for-agents/plans/062-aurelius-reconcile-runtime-security-and-docs.md)

## Baseline

- Review found three concrete problems:
  - Attic owner drift into file-sourced shell glue
  - tracked docs/examples no longer matching private runtime wiring
  - private `sudo` surface on `aurelius` broader than necessary

## Slices

### Slice 1

- Restored narrow tracked option contracts for:
  - [attic-client.nix](/home/higorprado/nixos/modules/features/system/attic-client.nix)
  - [attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
  - [github-runner.nix](/home/higorprado/nixos/modules/features/system/github-runner.nix)
- Re-aligned the real private overrides to those tracked contracts:
  - `private/hosts/aurelius/services.nix`
  - `private/hosts/predator/services.nix`
- Reduced one Attic publisher smell while keeping the post-build-hook shape:
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

- Revalidated the reconciled tracked contract locally:
  - `./scripts/check-repo-public-safety.sh` passed
  - `./scripts/check-docs-drift.sh` passed
  - `./scripts/run-validation-gates.sh structure` passed
  - `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath` passed
  - `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` passed
- Revalidated local runtime shaping after the restored Attic contract:
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` passed
  - the resulting build output showed the restored automatic Attic wiring in use:
    - `attic-post-build-hook.drv` was rebuilt
    - `extra-substituters`/`extra-trusted-public-keys` were active through the
      tracked owner again
    - the build consumed real cache paths from
      `http://your-attic-host:8080/aurelius`
- The only remaining proof gap is remote host re-application with the narrowed
  private `sudo` surface was closed after Tailscale SSH access was approved:
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
    got past the old Tailscale SSH gate and into real closure copy on the host
  - direct remote proof on `aurelius` also showed the reduced `NOPASSWD` set is
    sufficient for the real operator flow:
    - `sudo --non-interactive /run/current-system/sw/bin/nix --version`
    - `sudo --non-interactive /nix/var/nix/profiles/system/bin/switch-to-configuration test`

## Current State

- Decision taken for Attic: restore the narrow tracked option contract
  (`custom.attic.client.*` and `custom.attic.publisher.*`) instead of keeping
  undocumented raw private wiring.
- Tracked code, tracked examples, and the real private overrides are back on the
  same contract for:
  - Attic client
  - Attic publisher
  - GitHub runner
- The private `sudo` surface on `aurelius` is now narrower while still covering
  the proven remote operator path.
