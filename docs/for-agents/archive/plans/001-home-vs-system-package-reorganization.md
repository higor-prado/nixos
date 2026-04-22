# Home vs System Package Reorganization

## Goal

Reorganize package ownership so the repo has an explicit, easy-to-follow rule for deciding when a package belongs in NixOS vs Home Manager, while preserving current behavior as much as possible and keeping the host composition model explicit.

## Scope

In scope:
- codify the package ownership rule in agent docs
- reorganize ambiguous package bundles so ownership matches machine-vs-user responsibility
- move package policy out of `hardware/` where it does not belong
- keep feature behavior explicit through published `flake.modules.nixos.*` and `flake.modules.homeManager.*`
- preserve existing host selections in `modules/hosts/*.nix`

Out of scope:
- changing enabled features per host
- changing private overrides under `private/`
- redesigning host composition architecture
- desktop/session swaps
- opportunistic behavior changes unrelated to package ownership clarity

## Current State

- Host composition is already explicit in:
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
  - `modules/hosts/cerebelo.nix`
- The repo already follows the broad rule:
  - NixOS owns machine/runtime concerns
  - Home Manager owns user environment concerns
  - some features are intentionally split across both
- Ambiguous package ownership remains in these areas:
  - `modules/features/dev/packages-toolchains.nix`
  - `modules/features/dev/packages-docs-tools.nix`
  - `modules/features/system/packages-server-tools.nix`
  - `modules/features/system/attic-client.nix`
  - `modules/features/system/podman.nix`
  - `modules/hosts/predator.nix` (`predator-tui` in `environment.systemPackages`)
  - `hardware/predator/packages.nix`
- `hardware/predator/hardware/gpu-nvidia.nix` also still carries `nixpkgs.config.allowUnfree = true`, which conflicts with the documented ownership rule for nixpkgs policy.
- Analysis report already exists at:
  - `docs/for-agents/current/001-home-vs-system-package-placement-report.md`

## Desired End State

- The repo documents one explicit package ownership decision rule.
- New package placement is obvious from the docs and existing examples.
- User-interactive tools default to Home Manager.
- Machine/runtime-support tools remain in NixOS.
- Mixed-capability features are split cleanly when needed.
- `hardware/` contains machine support only, not general package policy.
- Host files remain explicit import owners and only carry narrow host-only additions.
- Validation gates pass after each meaningful slice.

## Phases

### Phase 0: Baseline

Targets:
- confirm current report and active file layout
- establish a no-surprises validation baseline

Changes:
- none

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`

Diff expectation:
- no code changes

Commit target:
- none

### Phase 1: Codify the rule in docs

Targets:
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/001-repo-map.md` if naming/ownership notes need a short clarification
- `docs/for-agents/999-lessons-learned.md` if a durable lesson should be added

Changes:
- add a short “package ownership rule” section:
  - NixOS for machine-owned/runtime-owned packages
  - Home Manager for user-interactive packages
  - split features when one capability spans both
  - keep package policy out of `hardware/` unless inseparable from machine support
- add at least one concrete example of each category already present in the repo

Validation:
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- docs only

Commit target:
- `docs: codify package ownership rule`

### Phase 2: Move clearly user-owned package bundles to Home Manager

Targets:
- `modules/features/dev/packages-toolchains.nix`
- `modules/features/dev/packages-docs-tools.nix`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`

Changes:
- convert `packages-docs-tools` to Home Manager ownership unless a concrete system-owned dependency appears during review
- move the package list in `packages-toolchains` to Home Manager and keep only true machine-owned parts in NixOS, if any remain
- move `predator-tui` out of host `environment.systemPackages` into a user-owned HM module or a narrow host-owned HM addition
- update host import lists accordingly

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- closures may shift from system profile to user profile, but user-visible tools should remain available
- no intended host feature changes

Commit target:
- `refactor(packages): move user-owned tool bundles to home-manager`

### Phase 3: Split mixed bundles into machine-support vs user-tool owners

Targets:
- `modules/features/system/packages-server-tools.nix`
- `modules/features/system/podman.nix`
- possibly `modules/features/system/attic-client.nix`
- host files that import them

Changes:
- split `packages-server-tools` into clearer owners, for example:
  - NixOS: admin/debug/network/host-diagnostics tools
  - Home Manager: interactive CLI ergonomics that are really user tools
- keep `virtualisation.podman` in NixOS and move `distrobox` to HM unless a system-owned requirement is proven
- decide whether `attic-client` belongs as:
  - a NixOS runtime dependency of publisher workflows, or
  - a user/operator CLI package in HM,
  and refactor accordingly
- rename modules if needed so ownership is obvious from file names

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.cerebelo.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel`

Diff expectation:
- package ownership becomes clearer; some closure movement is expected
- no intended service or runtime behavior changes

Commit target:
- `refactor(packages): split mixed machine and user package bundles`

### Phase 4: Remove package policy from hardware owners

Targets:
- `hardware/predator/packages.nix`
- `hardware/predator/default.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- possibly new feature modules under `modules/features/desktop/` or `modules/features/system/`
- `modules/hosts/predator.nix`

Changes:
- remove package bundle ownership from `hardware/predator/packages.nix`
- relocate `nvtopPackages.nvidia` and `tpm2-tools` to the correct owner:
  - HM if they are user-facing tools
  - NixOS if they are truly machine/admin support
- remove `nixpkgs.config.allowUnfree = true` from `hardware/predator/hardware/gpu-nvidia.nix` because that policy already belongs in `modules/features/core/nixpkgs-settings.nix`
- keep hardware files focused on hardware support only

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- no intended functional change; only owner cleanup
- predator package/provider closures may move between host, feature, and HM layers

Commit target:
- `refactor(hardware): remove package policy from predator hardware owners`

### Phase 5: Optional naming cleanup for long-term clarity

Targets:
- any renamed package bundle modules
- host imports referencing them
- `docs/for-agents/001-repo-map.md`

Changes:
- rename generic `packages-*` modules where needed so names describe ownership and intent more clearly
- examples:
  - machine/admin/debug bundles stay under system with explicit names
  - user workflow bundles move to HM with user-oriented names
- update docs to match final naming

Validation:
- `./scripts/run-validation-gates.sh structure`
- targeted `nix eval` for touched hosts
- full builds for touched hosts if module names/import surfaces changed materially

Diff expectation:
- mostly structural clarity; no intended behavior change

Commit target:
- `refactor(naming): clarify package owner module names`

## Risks

- Moving packages from NixOS to Home Manager can unintentionally remove tools from non-login/root contexts.
- Some packages currently in `environment.systemPackages` may be indirectly relied on by scripts or service units.
- Renaming modules can create drift in docs and host import lists.
- Closure movement may be correct architecturally but still surprising operationally.
- Per Rule 999, if validation reveals unrelated repo failures, stop and ask before proceeding.

## Definition of Done

- The package ownership rule is documented in the active operating docs.
- Ambiguous user-owned package bundles no longer default to NixOS just because they are “wanted on the host”.
- Mixed bundles are split or renamed so their ownership is obvious.
- `hardware/` no longer carries general package policy for Predator.
- Host imports remain explicit and readable.
- Required validation gates pass for all touched slices.
