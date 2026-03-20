# Predator Gaming Stack Plan

## Goal

Add a den-native gaming stack for `predator` centered on Steam, modern Linux game tooling, and measured performance tuning, while keeping reusable behavior in `modules/features/` and Predator-specific tuning in `hardware/predator/`.

## Scope

In scope:
- add a new tracked gaming feature under `modules/features/`
- enable Steam and core Linux gaming tooling for `predator`
- tune game-launch behavior for NVIDIA + Niri + Xwayland where needed
- refine Predator-specific performance knobs only where they are hardware-owned
- validate each slice with the repo’s required Nix gates
- document launch/benchmark expectations in tracked docs if needed

Out of scope:
- private overrides under `private/`
- BIOS/firmware overclocking, undervolting, or EC hacks
- broad desktop-composition rewrites
- per-game anti-cheat workarounds
- opening network/firewall ports unless a concrete gaming use case requires them

## Current State

- `modules/hosts/predator.nix` composes the desktop workstation and already includes `xwayland`, `audio`, `desktop-dms-on-niri`, and the NVIDIA-backed hardware import chain.
- `hardware/predator/hardware/gpu-nvidia.nix` already enables unfree NVIDIA drivers, 32-bit graphics, Wayland/NVIDIA session variables, and the latest packaged NVIDIA driver.
- `hardware/predator/performance.nix` already applies OOM protection, sysctl tuning, `ananicy-cpp`, `intel_pstate=active`, and a `powersave` governor with HWP boost.
- `hardware/predator/hardware/laptop-acer.nix` already forces an ACPI platform profile oriented toward performance and disables conflicting power-management services.
- There is no tracked gaming feature today: no `programs.steam`, `gamemode`, `gamescope`, `mangohud`, `heroic`, `lutris`, or similar entries were found under `modules/` or `hardware/`.
- The repo rules require reusable behavior in `modules/features/`, host-specific hardware behavior in `hardware/<host>/`, den-native aspect wiring, and validation after each meaningful slice.

## Desired End State

- `predator` includes a reusable gaming aspect, likely `modules/features/desktop/gaming.nix`.
- Steam works declaratively on `predator` with the required 32-bit/runtime support.
- Core tools for Linux gaming are available in a coherent stack, split into required vs optional pieces.
- Performance-sensitive tuning is explicit and minimal: shared launch/runtime behavior in the feature, Predator-only hardware/power tuning in `hardware/predator/`.
- The final configuration is validated with the repo gate set and compared against a pre-change baseline.

## Phases

### Phase 0: Baseline

Targets:
- confirm the current `predator` eval/build baseline before gaming changes
- capture the current closure so post-change diffing is meaningful

Changes:
- no config changes
- record the baseline derivation/output path for `predator`

Validation:
- `nix flake metadata`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- no diff; baseline only

Commit target:
- none

### Phase 1: Shared Gaming Feature

Targets:
- add `modules/features/desktop/gaming.nix` as the owner of the shared gaming stack
- include it from `modules/hosts/predator.nix`

Changes:
- declare a den aspect with:
- NixOS-owned gaming enablement such as `programs.steam` and shared runtime requirements
- Home Manager-owned user packages for gaming tooling that should live in the user environment
- install a focused core stack first:
- Steam
- GameMode
- MangoHud
- Gamescope
- Proton support helpers such as `protontricks`
- one launcher layer, likely `heroic` and/or `lutris`, only if kept intentional and not redundant
- keep optional extras separated from the first slice so the core path stays easy to validate

Validation:
- `./scripts/run-validation-gates.sh`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- system closure gains Steam/runtime pieces and any system-side gaming services
- home closure gains user-facing gaming tools

Commit target:
- `feat(gaming): add shared steam and gaming stack`

### Phase 2: Predator Performance Tuning

Targets:
- tighten performance behavior for actual game sessions without leaking hardware policy into the shared feature

Changes:
- review whether `hardware/predator/performance.nix` should add game-specific tuning rather than more global tuning
- prefer targeted settings over always-on aggressive defaults
- likely candidates:
- `gamemode` policy tuned for gaming sessions instead of global governor changes
- process-priority alignment between `gamemode` and existing `ananicy-cpp`
- NVIDIA-specific launch/runtime fixes only if required by measured behavior on `predator`
- keep battery/thermal safety intact and do not introduce tools that fight `linuwu-sense`, the ACPI profile hook, or the current laptop ownership model
- defer high-risk GPU power-limit/fan-control tooling unless the core stack is stable first

Validation:
- `./scripts/run-validation-gates.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix run nixpkgs#nvd -- diff /tmp/predator-baseline /tmp/predator-new` or equivalent closure diff
- local runtime smoke for Steam launch, a Gamescope path, and service status checks as applicable

Diff expectation:
- small system diff, mostly service/config changes rather than large package churn

Commit target:
- `feat(predator): tune gaming performance path`

### Phase 3: Measurement And Polish

Targets:
- confirm the tuning is actually useful and make the workflow repeatable

Changes:
- benchmark a small representative set:
- one native/Vulkan game
- one Proton title
- one Gamescope-enabled launch path if used
- capture what launch options are actually needed, for example `mangohud`, `gamemoderun`, or `gamescope` wrappers
- add brief tracked documentation only for the final supported workflow

Validation:
- rerun `./scripts/run-validation-gates.sh`
- rerun the relevant `nix build --no-link` commands
- verify runtime behavior manually on `predator`

Diff expectation:
- docs and minor config polish only

Commit target:
- `docs(gaming): record supported launch workflow`

## Risks

- Steam on NVIDIA + Wayland + Xwayland + Gamescope can fail in ways that only show up at runtime.
- Global performance tuning can hurt thermals, fan noise, battery life, or interact badly with the existing Acer platform-profile ownership.
- Adding too many launchers or overlays in the first slice makes regression isolation harder.
- Some tuning ideas are placebo unless they are benchmarked on this actual laptop.

## Definition of Done

- a gaming feature exists under `modules/features/` and is included by `predator`
- Steam is declaratively enabled and builds successfully
- the chosen gaming toolchain is available without mixing ownership boundaries
- Predator-specific tuning remains in `hardware/predator/` and stays compatible with the existing Acer/NVIDIA setup
- required validation gates pass
- a before/after closure diff and basic runtime check confirm the change is real and reversible
