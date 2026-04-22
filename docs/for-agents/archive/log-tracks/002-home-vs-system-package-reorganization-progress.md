# Home vs System Package Reorganization Progress

## Status

In progress

## Related Plan

- `docs/for-agents/plans/001-home-vs-system-package-reorganization.md`

## Baseline

- Analysis report exists at `docs/for-agents/current/001-home-vs-system-package-placement-report.md`.
- Package ownership rule is not yet explicit enough in the operating docs.
- Baseline structural validation previously passed.

## Slices

### Slice 1

- Goal: codify the package ownership rule in operating docs.
- Changed:
  - `docs/for-agents/003-module-ownership.md`
    - added an explicit package ownership rule
    - added concrete NixOS / Home Manager / split examples already present in the repo
  - `docs/for-agents/001-repo-map.md`
    - added a short package ownership map near the top-level runtime section
  - `docs/for-agents/999-lessons-learned.md`
    - added a durable lesson for package ownership
- Validation run:
  - `./scripts/run-validation-gates.sh structure` ✅
- Diff result:
  - docs-only slice
- Commit:
  - not created in this session

### Slice 2

- Goal: move clearly user-owned package bundles to Home Manager.
- Changed:
  - `modules/features/dev/packages-docs-tools.nix`
    - moved `packages-docs-tools` from `flake.modules.nixos.*` to `flake.modules.homeManager.*`
  - `modules/features/dev/packages-toolchains.nix`
    - moved the toolchain package list from `environment.systemPackages` to `home.packages`
    - kept the existing Fish path setup in the HM owner
  - `modules/hosts/predator.nix`
    - removed `nixos.packages-docs-tools`
    - removed `nixos.packages-toolchains`
    - added `homeManager.packages-docs-tools`
    - kept `homeManager.packages-toolchains`
    - moved `customPkgs.predator-tui` from host `environment.systemPackages` to user `home.packages`
  - `modules/hosts/aurelius.nix`
    - removed `nixos.packages-toolchains`
- Validation run:
  - `nix flake metadata` ✅
  - `./scripts/run-validation-gates.sh structure` ✅
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion` ✅
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
  - `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path.drvPath` ✅
- Diff result:
  - package ownership moved from system profile to user profile for clearly user-owned tool bundles
  - no host feature selection changes
- Commit:
  - not created in this session

### Slice 3

- Goal: split mixed machine-support vs user-tool bundles.
- Changed:
  - `modules/features/system/packages-server-tools.nix`
    - kept machine/admin diagnostics in the NixOS owner: `lsof`, `strace`, `bind`, `mtr`, `iperf3`, `tcpdump`
    - moved interactive server CLI tools to a new HM owner in the same file: `eza`, `bat`, `fd`, `ripgrep`, `jq`, `yq-go`, `tmux`, `btop`, `ncdu`
  - `modules/features/system/podman.nix`
    - kept Podman runtime enablement in NixOS
    - moved `distrobox` to a new HM owner in the same file
  - `modules/features/system/attic-client.nix`
    - moved `attic-client` from NixOS to HM
  - `modules/hosts/aurelius.nix`
    - added `homeManager.packages-server-tools`
  - `modules/hosts/cerebelo.nix`
    - added `homeManager.packages-server-tools`
    - added `homeManager.podman`
    - replaced `nixos.attic-client` with `homeManager.attic-client`
  - `modules/hosts/predator.nix`
    - added `homeManager.podman`
    - replaced `nixos.attic-client` with `homeManager.attic-client`
- Validation run:
  - `./scripts/run-validation-gates.sh structure` ✅
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
  - `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath` ✅
  - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path.drvPath` ✅
- Diff result:
  - mixed package owners are now split more explicitly between machine/runtime and user/interactive concerns
  - host feature selection remains unchanged
- Commit:
  - not created in this session

### Slice 4

- Goal: remove package policy from Predator hardware owners.
- Changed:
  - `hardware/predator/default.nix`
    - removed the `./packages.nix` import from hardware composition
  - `hardware/predator/hardware/gpu-nvidia.nix`
    - removed `nixpkgs.config.allowUnfree = true`
    - unfree policy now remains owned by `modules/features/core/nixpkgs-settings.nix`
  - `hardware/predator/packages.nix`
    - turned into an intentionally empty module so package policy no longer lives in `hardware/`
  - `modules/hosts/predator.nix`
    - added host-owned `environment.systemPackages = [ tpm2-tools ]`
    - added host-owned HM `home.packages = [ predator-tui nvtopPackages.nvidia ]`
- Validation run:
  - first attempt surfaced a regression: moving `nvtopPackages.nvidia` via `legacyPackages` in HM bypassed the repo's `allowUnfree` policy and failed evaluation
  - corrected by using the HM module-local `pkgs` for `nvtopPackages.nvidia`
  - final validation:
    - `./scripts/run-validation-gates.sh structure` ✅
    - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` ✅
    - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` ✅
    - `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` ✅
    - `nix eval path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path.drvPath` ✅
    - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath` ✅
    - `nix eval path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path.drvPath` ✅
- Diff result:
  - Predator-specific package ownership is now outside `hardware/`
  - GPU monitoring is user-owned in HM
  - TPM2 CLI remains machine/admin-owned in the concrete host owner
- Commit:
  - not created in this session

## Final State

- Phase 1 complete: package ownership rule is explicit in the operating docs.
- Phase 2 complete for clearly user-owned package bundles.
- Phase 3 complete for `packages-server-tools`, `podman`, and `attic-client`.
- Phase 4 complete for Predator hardware package-policy cleanup.
- Open: optional Phase 5 naming cleanup if you want clearer module names for long-term maintainability.
