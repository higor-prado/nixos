# Packages-Server-Tools Correction Plan

## Goal

Fix the one remaining broken piece of the package-ownership reorganization: the Home Manager half of `packages-server-tools` duplicates packages already canonically owned by other HM features, causing real `buildEnv` collisions on `aurelius` and `cerebelo`.

## Scope

In scope:
- correct the HM half of `packages-server-tools` so it no longer overlaps with existing canonical HM owners
- update host imports for `aurelius` and `cerebelo` accordingly
- remove the dead `hardware/predator/packages.nix` file
- validate all three hosts build cleanly

Out of scope:
- changing the NixOS half of `packages-server-tools` (it is correct)
- changing any other reorganization result (all others are correct per the cross-host analysis)
- changing private overrides
- renaming modules (optional naming cleanup deferred)
- touching `predator` host (it does not import the HM half and is unaffected)

## Current State

### What is broken

`homeManager.packages-server-tools` (in `modules/features/system/packages-server-tools.nix`) currently adds these packages to the HM profile:

| Package | Already owned by | Collision risk |
|---------|-----------------|----------------|
| `eza` | `dev-tools` via `programs.eza` | **duplicate** |
| `bat` | `dev-tools` via `programs.bat` | **duplicate** |
| `fd` | `dev-tools` via `home.packages` | **duplicate** |
| `ripgrep` | `core-user-packages` via `home.packages` | **duplicate** |
| `jq` | `dev-tools` via `home.packages` | **duplicate** |
| `tmux` | `terminal-tmux` via `programs.tmux` | **duplicate** |
| `btop` | `core-user-packages` via `programs.btop` | **duplicate** |
| `yq-go` | no other owner | **unique** |
| `ncdu` | no other owner | **unique** |

Both `aurelius` and `cerebelo` import the overlapping HM owners together with `homeManager.packages-server-tools`, producing `buildEnv` conflicts.

### What is correct and stays

- NixOS half of `packages-server-tools`: `lsof`, `strace`, `bind`, `mtr`, `iperf3`, `tcpdump` — machine/admin diagnostics
- All other reorganization results (docs-tools, toolchains, podman split, attic-client, predator hardware cleanup)

### Dead residue

- `hardware/predator/packages.nix` — intentionally empty, no longer imported by `hardware/predator/default.nix`

## Desired End State

- The HM half of `packages-server-tools` contains **only** packages not already owned by another canonical HM feature
- On `aurelius` and `cerebelo`, all HM imports compose without `buildEnv` conflicts
- Dead `packages.nix` under `hardware/predator/` is deleted
- All validation gates pass for all three hosts
- The NixOS half of `packages-server-tools` is untouched

## Phases

### Phase 0: Baseline validation

Targets:
- confirm current working tree state

Changes:
- none

Validation:
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- no code changes

### Phase 1: Remove overlapping packages from HM server-tools owner

Targets:
- `modules/features/system/packages-server-tools.nix`

Changes:
- remove `eza`, `bat`, `fd`, `ripgrep`, `jq`, `tmux`, `btop` from the `homeManager.packages-server-tools` bundle
- keep only `yq-go` and `ncdu` (the two packages with no other canonical HM owner)
- the NixOS half remains unchanged

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path.drvPath`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path.drvPath`

Diff expectation:
- 7 packages removed from the HM server-tools owner
- those packages remain available through their canonical HM owners on all hosts
- no behavioral change for the user

Commit target:
- `fix(packages-server-tools): remove HM packages that duplicate canonical owners`

### Phase 2: Delete dead predator packages.nix

Targets:
- `hardware/predator/packages.nix`

Changes:
- delete the file (already empty and not imported)

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- dead file removed
- no functional change

Commit target:
- `chore: remove dead hardware/predator/packages.nix`

### Phase 3: Full cross-host validation

Targets:
- all three hosts

Changes:
- none

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path`

Diff expectation:
- no additional changes
- this phase confirms correctness end-to-end

Commit target:
- none (validation only)

### Phase 4: Archive completed work

Targets:
- active docs

Changes:
- update progress log
- move completed plan to archive

Validation:
- docs drift check passes

## Risks

- Removing packages from the HM server-tools owner means `yq-go` and `ncdu` become the only remaining HM packages in that module. If the module feels too thin afterwards, the entire HM half could be removed and the two survivors absorbed into a more natural owner. This decision is deferred to execution — both options are safe.
- `aurelius` and `cerebelo` host files currently import `homeManager.packages-server-tools`. After phase 1, the import is still valid (just smaller). If the HM half is eventually removed entirely, those host imports would need updating in a follow-up.
- The NixOS half is imported by `aurelius` and `cerebelo` only. It is not imported by `predator`. This asymmetry is intentional per host composition.

## Definition of Done

- The HM half of `packages-server-tools` no longer duplicates any package from `core-user-packages`, `dev-tools`, or `terminal-tmux`
- `aurelius` builds without `buildEnv` conflicts
- `cerebelo` builds without `buildEnv` conflicts
- `predator` is unaffected and still builds
- `hardware/predator/packages.nix` is deleted
- All validation gates pass
