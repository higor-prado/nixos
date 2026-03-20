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

### Slice 2

- Added [repo-runtime-contracts.nix](/home/higorprado/nixos/modules/options/repo-runtime-contracts.nix)
  so the shadow path now owns its own lower-level runtime contracts and context
  bridge without relying on `den`
- Updated [shadow-hosts.nix](/home/higorprado/nixos/modules/options/shadow-hosts.nix)
  so the shadow hosts now consume:
  - `hardwareImports`
  - `extraSystemPackages`
  - repo-owned `custom.host.role`
  - repo-owned `custom.user.name`
  - repo-owned `repo.context`
- Corrected two implementation mistakes in this slice:
  - lower-level host modules had mixed `config.*` assignments with top-level
    config attrs; fixed by moving the lower-level config into an explicit
    `config = { ... };` block
  - the temporary tmpfs/container fallback conflicted with real hardware imports;
    fixed by making it conditional only when a shadow host has no
    `hardwareImports`
- Validation:
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.custom.host.role`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.predator.config.custom.user.name`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.custom.host.role`
  - `nix eval --raw path:$PWD#dendritic.nixosConfigurations.aurelius.config.custom.user.name`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - `predator` shadow now builds both system and HM
  - `predator` shadow exposes the same host/user compatibility bridge names as
    the authoritative path
  - `aurelius` shadow resolves runtime role and user bridge values
  - authoritative `den` validation path remains green

### Slice 3

- Extended the repo-local host inventory with explicit feature selection in
  [inventory.nix](/home/higorprado/nixos/modules/options/inventory.nix)
- Updated [shadow-hosts.nix](/home/higorprado/nixos/modules/options/shadow-hosts.nix)
  so shadow hosts now import lower-level modules selected from top-level
  feature names
- Dual-published the first real feature owner,
  [llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix),
  onto the repo-local runtime:
  - `flake.modules.nixos.llm-agents`
  - `flake.modules.homeManager.llm-agents`
- Enabled `llm-agents` for the `predator` shadow host via
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Validation:
  - `nix eval --apply 'pkgs: builtins.length pkgs' path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.packages`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - `predator` shadow HM package count is now `13`
  - the `predator` shadow HM and system paths both build with a real feature
    imported through the repo-local runtime
  - authoritative `den` validation path remains green

### Slice 4

- Dual-published the host-aware core owner
  [nix-settings.nix](/home/higorprado/nixos/modules/features/core/nix-settings.nix)
  onto the repo-local runtime as `flake.modules.nixos.nix-settings`
- Started using repo-local default feature selection in
  [den-defaults.nix](/home/higorprado/nixos/modules/features/core/den-defaults.nix)
  through `repo.defaults.hostFeatures = [ "nix-settings" ]`
- Validation:
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.nix.settings.trusted-users`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.nix.settings.trusted-users`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.predator.config.programs.nh.enable`
  - `nix eval --json path:$PWD#dendritic.nixosConfigurations.aurelius.config.programs.nh.enable`
  - `nix build --no-link --print-out-paths path:$PWD#dendritic.nixosConfigurations.predator.config.system.build.toplevel`
  - `./scripts/run-validation-gates.sh`
- Outcome:
  - both shadow hosts now resolve `nix.settings.trusted-users = [ "root" "higorprado" ]`
  - both shadow hosts now resolve `programs.nh.enable = true`
  - `predator` shadow system still builds after adding a global host-aware
    default feature
  - authoritative `den` validation path remains green

## Final State

- Not complete yet
- Phase 0 baseline is captured for the current authoritative outputs
- Phase 1 has a validated shadow namespace that now builds `predator`
- Phase 2 has started: the shadow path now consumes repo-owned inventory and
  runtime contracts in a more realistic way
- Phase 3 has started in small form: one real feature (`llm-agents`) now flows
  through the repo-local runtime
- Another host-aware owner (`nix-settings`) now flows through the repo-local
  default feature path
- Next step: keep migrating small owners that exercise both HM and NixOS routing
  through the local runtime without touching the authoritative outputs
