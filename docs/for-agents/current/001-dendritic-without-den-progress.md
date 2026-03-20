# Dendritic Without Den Migration Progress

## Status

In progress

## Related Plan

- [002-dendritic-without-den-migration.md](/home/higorprado/nixos/docs/for-agents/plans/002-dendritic-without-den-migration.md)

## Baseline

- Working branch: `dendritic-without-den`
- Starting point: repo on commit `65692d6` on top of the post-`bidirectional`-removal `den` shape
- Current authoritative baseline:
  - `predator` system `stateVersion = 25.11`
  - `predator` HM `stateVersion = 25.11`
  - `predator` `custom.host.role = desktop`
  - `predator` `custom.user.name = higorprado`
  - `predator` HM package count = `141`
  - `predator` `programs.git.enable = true`
  - `predator` `programs.starship.enable = true`
  - `predator` HM out path = `/nix/store/9aqwfh74yvdnlwf6jqr1an6xirrgy423-home-manager-path`
  - `predator` system out path = `/nix/store/lbry9rp09m2690i5k0yqx9y1qz80lbla-nixos-system-predator-26.05.20260318.b40629e`
- Active objective: finish Phase 0 baseline and land the first Phase 1 skeleton

## Slices

### Slice 1

- Created the active plan and opened the execution branch
- Captured the parity baseline for the current authoritative `den` outputs
- Added a repo-local dendritic skeleton under `modules/options/`:
  - `flake-parts` lower-level module registry import
  - top-level `configurations.nixos` option
  - repo-owned `repo.hosts` / `repo.users` inventory
  - namespaced shadow outputs under `flake.dendritic.nixosConfigurations`
  - repo-owned lower-level context modules for the shadow path
- Dual-published host/user inventory in:
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
  - `modules/users/higorprado.nix`
- Corrected two mistakes during the slice:
  - moved option-owning files from `modules/framework/` to `modules/options/`
    to satisfy the repo boundary gate
  - moved shadow outputs out of canonical `flake.nixosConfigurations` into the
    `flake.dendritic` namespace so existing validation scripts keep treating
    only the real hosts as authoritative
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.system.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.system.stateVersion`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - shadow `dendritic` namespace evaluates for `predator` and `aurelius`
  - authoritative `den` validation path remains green

## Final State

- Not complete yet
- Phase 0 baseline is captured for the current authoritative outputs
- Phase 1 has started with a validated shadow namespace
- Next step: start migrating repo-owned inventory/context consumers into the
  new local framework without changing the authoritative outputs
