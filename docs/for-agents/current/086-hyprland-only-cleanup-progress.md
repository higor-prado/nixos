# Hyprland-Only Desktop Cleanup Progress

## Status

In progress

## Related Plan

- [086-hyprland-only-cleanup.md](/home/higorprado/nixos/docs/for-agents/plans/086-hyprland-only-cleanup.md)

## Baseline

- Started from clean `main` after:
  - `c3c8887 chore: snapshot current hyprland work`
  - `0fd955d fix(desktop): remove hyprland idle locking`
- Created rollback tags:
  - `pre-hyprland-migration` -> `3f0f271`
  - `pre-hyprland-only-cleanup` -> `0fd955d`
- Created cleanup branch:
  - `cleanup/hyprland-only`
- Built baseline closure:
  - `/tmp/predator-hyprland-before-cleanup`

## Slices

### Slice 1

- Collapsed `modules/hosts/predator.nix` to a single Hyprland desktop path.
- Removed old Niri/Noctalia import lists and commented selector lines.
- Validation:
  - `nix eval path:$PWD#nixosConfigurations.predator.config.programs.hyprland.enable`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.programs.regreet.enable`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
  - `./scripts/check-config-contracts.sh`
- Diff result:
  - predator host composition now declares only the Hyprland desktop import lists.
- Commit:
  - `413cc82 refactor(hosts): make predator hyprland-only`

### Slice 2

- Removed live Niri/DMS/Noctalia source surfaces:
  - deleted old desktop compositions, feature modules, payloads, and DMS package support;
  - removed `dms`, `niri`, `noctalia`, and `dms-awww-src` from `flake.nix`;
  - pruned Noctalia Cachix, DMS persisted path, NVIDIA Niri profile, `dms-open.desktop`, and dead `xwayland` module.
- Validation:
  - `nix flake metadata`
  - `./scripts/check-flake-inputs-used.sh`
  - `./scripts/check-feature-publisher-name-match.sh`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- Diff result:
  - live source no longer contains Niri/DMS/Noctalia owners or payloads.
- Commits:
  - `7668ce3 refactor(desktop): remove niri dms and noctalia surfaces`
  - `2dc111f chore(lock): prune removed desktop inputs`

### Slice 3

- Narrowed active tests/scripts to Hyprland-only:
  - `scripts/check-desktop-composition-matrix.sh`
  - `scripts/new-host-skeleton.sh`
  - `tests/scripts/new-host-skeleton-fixture-test.sh`
  - `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
  - `scripts/check-config-contracts.sh`
  - `scripts/check-runtime-smoke.sh`
- Validation:
  - `./scripts/check-desktop-composition-matrix.sh`
  - `bash tests/scripts/new-host-skeleton-fixture-test.sh`
  - `./scripts/check-config-contracts.sh`
  - `bash tests/scripts/gate-cli-contracts-test.sh`
- Diff result:
  - active checks/generator no longer model Niri/DMS desktop experiences.
- Commit:
  - `82ac308 test(desktop): narrow desktop checks to hyprland`

### Slice 4

- Updated living docs to remove deleted path references and Niri/DMS/Noctalia guidance.
- Validation so far:
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh structure`
- Diff result:
  - docs drift caused by deleted desktop files was cleared.
- Commit:
  - pending

## Final State

- Cleanup branch and rollback tags exist.
- Predator is Hyprland-only in tracked host composition.
- Live source no longer ships Niri/DMS/Noctalia modules or payloads.
- Active scripts/tests now assume Hyprland-only desktop composition.
- Remaining work:
  - commit the living-doc updates;
  - run final full validation and closure diff;
  - review final `rg` output for intentional exceptions in active plan docs.
