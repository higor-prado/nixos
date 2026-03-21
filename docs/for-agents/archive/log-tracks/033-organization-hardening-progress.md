# Organization Hardening Progress

## Status

In progress

## Related Plan

- [033-organization-hardening-plan.md](/home/higorprado/nixos/docs/for-agents/plans/033-organization-hardening-plan.md)

## Baseline

- Current branch: `dendritic-without-den`
- Current active plan: organization hardening after Den removal
- Current dirty tracked file before execution:
  - `flake.lock`
- Key baseline concerns confirmed:
  - `modules/users/higorprado.nix` currently owns both repo-wide groups and
    likely host-specific groups
  - `modules/hosts/predator.nix` and `modules/hosts/aurelius.nix` repeat a
    large shared baseline import block
  - `repo.hosts.*` currently stores both inventory-like facts and runtime-heavy
    values (`inputs`, `customPkgs`, `hardwareImports`, etc.)
  - `custom.user.name` still exists as a compatibility bridge used by scripts

## Slices

### Slice 1

- Opened the execution track and confirmed the baseline organization issues
  against the current runtime.
- No structural changes yet.

Validation:
- baseline inspection only

Diff result:
- none

Commit:
- none

### Slice 2

- Narrowed the user owner in `modules/users/higorprado.nix` so it keeps only
  repo-wide primary-user groups.
- Moved Predator-only user entitlements into `modules/hosts/predator.nix`.
- Reduced tracked validation dependence on `custom.user.name` by switching the
  gate runner and config contracts to `config.repo.context.userName`.
- Kept the compatibility bridge itself intact because human docs and private
  override entry points still rely on it.
- Updated living docs to record the ownership split.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `./scripts/check-config-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- `predator` now evaluates with workstation-specific groups
- `aurelius` now evaluates with only `["wheel","networkmanager"]`
- tracked gate scripts no longer use `config.custom.user.name`
- direct `aurelius` system build remains platform-limited on this `x86_64-linux`
  machine, but the canonical gate runner passed because its Aurelius stage is
  eval-only by design

Commit:
- `ea8fa62` `refactor(runtime): narrow user ownership and reduce username bridge use`

### Slice 3

- Removed `hardwareImports` and `extraSystemPackages` from the tracked
  `repo.hosts.*` inventory schema.
- Kept those values local to the concrete host owners in
  `modules/hosts/predator.nix` and `modules/hosts/aurelius.nix`.
- Updated the host skeleton templates and fixtures so onboarding continues to
  teach the cleaned-up shape.
- Updated living architecture/onboarding docs so inventory is described as
  tracked host data, while hardware import lists and host-only package payloads
  stay local to the host file.

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- `repo.hosts.*` no longer stores host-only hardware import lists or
  host-specific package payloads
- concrete host files remain explicit, but the tracked inventory reads more
  cleanly as inventory instead of runtime baggage
- generated host skeletons now teach the corrected runtime boundary

Commit:
- `807afb5` `refactor(runtime): keep host inventory focused`

### Slice 4

- Introduced a local `repoContext` binding inside the concrete host modules for
  `predator` and `aurelius`.
- Reused that single value for both NixOS `repo.context` and the nested
  Home Manager `repo.context`.
- Updated the host skeleton templates, fixtures, and living architecture docs
  to teach the same shape.

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- concrete host composition stayed explicit
- duplicated `repo.context` assembly disappeared from real hosts and onboarding
  templates
- no new helper or option surface was introduced

Commit:
- pending

### Slice 6

- Removed raw `inputs` and `customPkgs` from the tracked `repo.hosts.*`
  inventory schema.
- Kept those values in the concrete host files and merged them into the
  runtime `host` payload that is exposed through `repo.context.host`.
- Updated host templates, fixtures, and living docs to teach the same
  inventory-vs-runtime split.

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff result:
- `repo.hosts.*` now reads more clearly as tracked inventory
- `repo.context.host` continues to provide the runtime payload needed by
  lower-level features without inventing a new option surface

Commit:
- pending

### Slice 5

- Removed the last tracked executable use of `custom.user.name` from the
  desktop composition matrix fixture.
- Tightened living docs so `custom.user.name` is described as a
  compatibility-only bridge for private overrides, not as a normal runtime
  surface.

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Diff result:
- tracked executable code no longer depends on `custom.user.name`
- the bridge remains available only for compatibility/private entry points

Commit:
- pending

## Final State

- Open
