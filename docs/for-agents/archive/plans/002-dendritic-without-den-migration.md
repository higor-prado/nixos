# Migrate From Den to Plain Dendritic Pattern

## Goal

Replace `den` with a repo-local top-level composition model that preserves the
current repository's modularity, host/user ownership boundaries, and
cross-configuration feature organization while staying aligned with the
dendritic pattern: every non-entry-point file remains a top-level module, and
lower-level NixOS/Home Manager modules are declared as top-level option values
instead of being wired through `den`.

## Scope

In scope:
- remove the `den` runtime and replace it with repo-local top-level modules
- keep `flake-parts` + top-level auto-import as the architectural base
- preserve current feature boundaries under `modules/features/`,
  `modules/desktops/`, `modules/hosts/`, and `modules/users/`
- preserve nested Home Manager under NixOS, but derive it from top-level
  declarations rather than `den` routing
- migrate validation scripts, fixtures, and docs that currently depend on `den`

Out of scope:
- changing the chosen desktop stack, host roles, or hardware organization
- changing private override shapes beyond what is required by the new routing
- redesigning feature ownership boundaries unrelated to `den`
- introducing `specialArgs` / `extraSpecialArgs` pass-through as the new model

## Current State

- [flake.nix](/home/higorprado/nixos/flake.nix) already uses `flake-parts` +
  `import-tree`, but [modules/den.nix](/home/higorprado/nixos/modules/den.nix)
  imports `inputs.den.flakeModule`, so composition and routing are delegated to
  `den`.
- The repo currently encodes almost all behavior in `den` terms:
  `68` tracked files under `modules/` reference `den.aspects`, `den.hosts`,
  `den.lib`, `den._`, `provides.to-users`, or `_.to-users`.
- Host inventory, host context, and host composition are owned by
  [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  and [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
  via `den.hosts.<system>.<host>` and `den.aspects.<host>`.
- User identity, base HM setup, and host-to-user wiring currently rely on
  [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
  plus `den._.define-user`, `den._.primary-user`, `den._.user-shell`, and
  `den._.mutual-provider`.
- Repo-wide defaults initially depended on a now-removed `den-defaults` shim
  that injected universal aspects through `den.default.includes`.
- Host-aware feature behavior currently depends on `den` context helpers such as
  `den.lib.parametric`, `den.lib.perHost`, and `den.lib.take.*` in files like
  [modules/features/dev/llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix),
  [modules/features/shell/fish.nix](/home/higorprado/nixos/modules/features/shell/fish.nix),
  [modules/features/core/nix-settings.nix](/home/higorprado/nixos/modules/features/core/nix-settings.nix),
  and a now-removed `user-context` shim.
- Host-owned HM is pervasive: `36` tracked feature/composition files publish
  `provides.to-users`, and hosts aggregate them via `_.to-users.includes`.
- Tooling and docs are also `den`-shaped:
  `14` tracked files under `scripts/`, `tests/`, and `docs/for-humans/`
  directly assume `den` APIs or `den` architecture.

## Desired End State

- `den` and `flake-aspects` are removed from [flake.nix](/home/higorprado/nixos/flake.nix).
- Every tracked non-entry-point Nix file remains a top-level module imported by
  `flake-parts` / `import-tree`, consistent with the dendritic pattern.
- Lower-level modules are declared as top-level option values, primarily using
  `flake-parts.modules` registries and `deferredModule`.
- Host and user inventory are declared as top-level options owned by the repo,
  not by `den`.
- The repo has a local composition layer that derives:
  - NixOS configurations
  - nested Home Manager user imports
  - host/user context values
  from top-level declarations rather than `den` routing batteries.
- Host/user context is exposed to lower-level modules via ordinary options owned
  by the repo-local framework, not via `specialArgs` / `extraSpecialArgs`.
- Feature files keep their current ownership boundaries and continue to express
  behavior across configuration classes from a single top-level module.
- Scripts, fixtures, and human/agent docs describe the new local framework, not
  `den`.

## Phases

### Phase 0: Baseline and Parity Contract

Targets:
- current repo behavior for `predator` and `aurelius`
- baseline inventory of `den`-specific responsibilities

Changes:
- record the current sources of truth for:
  - host inventory
  - user identity and HM baseline
  - universal/default feature selection
  - host-owned HM routing
  - host-aware feature context
- capture parity metrics to compare during migration:
  - `predator` system closure
  - `predator` HM closure
  - `aurelius` system closure
  - key evaluated options such as `custom.user.name`,
    `custom.host.role`, `programs.git.enable`, `programs.starship.enable`,
    and selected package counts

Validation:
- `./scripts/run-validation-gates.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`

Diff expectation:
- no code change yet; this phase defines the parity contract

Commit target:
- none; planning baseline only

### Phase 1: Introduce a Repo-Local Dendritic Framework Surface

Targets:
- [flake.nix](/home/higorprado/nixos/flake.nix)
- new `modules/framework/*.nix` owners

Changes:
- keep `flake-parts` + `import-tree`
- import `inputs.flake-parts.flakeModules.modules`, following the dendritic
  example
- add repo-local top-level options for:
  - declared NixOS configurations
  - host inventory
  - user inventory
  - default feature selection
  - lower-level context bridges
- emit shadow outputs first, for example `nixosConfigurations.<host>-dendritic`,
  so the new framework can be evaluated side-by-side with the existing `den`
  outputs

Validation:
- `nix flake metadata path:$PWD`
- `nix eval path:$PWD#nixosConfigurations.predator-dendritic.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.aurelius-dendritic.config.system.stateVersion`

Diff expectation:
- no behavioral change to the current authoritative outputs
- new shadow outputs exist but can still be skeletal

Commit target:
- `feat(framework): add local dendritic composition skeleton`

### Phase 2: Model Host and User Inventory as Top-Level Data

Targets:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
- the former `den-host-context` schema shim
- new framework context modules

Changes:
- rewrite host files so they declare repo-local host inventory and configuration
  facts, not `den.hosts.*`
- move `inputs`, `customPkgs`, `llmAgents`, tracked users, and host-level
  metadata into repo-owned top-level options
- replace `den._.define-user`, `den._.primary-user`, and `den._.user-shell`
  with repo-owned user declarations and lower-level modules emitted from the
  top-level configuration
- replace `den-host-context` schema extension with repo-local context options
  that are set by the framework and consumed by lower-level modules

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator-dendritic.config.users.users.higorprado`
- `nix eval --raw path:$PWD#nixosConfigurations.predator-dendritic.config.custom.user.name`
- `nix eval --raw path:$PWD#nixosConfigurations.predator-dendritic.config.custom.host.role`

Diff expectation:
- shadow configs resolve correct host/user identity and context
- current authoritative `den` outputs remain unchanged

Commit target:
- `refactor(framework): move host and user inventory into top-level options`

### Phase 3: Replace `den.default` and Feature Registry Semantics

Targets:
- the former `den.default` universal-include layer
- feature/desktops modules under `modules/features/` and `modules/desktops/`

Changes:
- convert feature files from `den.aspects.<name>` publishers to repo-local
  lower-level module publishers, using top-level registries such as:
  - `flake.modules.nixos.<name>`
  - `flake.modules.homeManager.<name>`
- keep the single-owner feature-file model intact
- replace `den.default.includes` with a repo-local default feature list that the
  framework merges into every host composition
- allow a temporary dual-publish period where a feature exports both the old
  `den` surface and the new local surface so shadow outputs can be compared

Validation:
- shadow configs evaluate with the migrated core/default features enabled
- `nix build --no-link path:$PWD#nixosConfigurations.predator-dendritic.config.system.build.toplevel`

Diff expectation:
- shadow configs begin to resemble current outputs for core/system behavior
- current authoritative outputs still stay on `den`

Commit target:
- `refactor(features): publish core features through local dendritic registries`

### Phase 4: Replace Host-to-User HM Routing With Repo-Local Derivation

Targets:
- all host-owned HM feature files currently using `provides.to-users`
- host files currently aggregating `_.to-users.includes`
- framework modules that derive nested HM user imports

Changes:
- remove the `den` routing model (`provides.to-users`, `_.to-users`,
  `den._.mutual-provider`) from the shadow path
- replace it with repo-local derivation driven by top-level declarations:
  the framework should determine which selected features have HM projections and
  attach them to the tracked host users automatically
- keep host/user context available to HM modules through repo-owned lower-level
  options rather than `extraSpecialArgs`
- migrate by category to keep diffs readable:
  - shell
  - dev/editors
  - desktop/media
  - system/services with HM projections
  - desktop compositions

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator-dendritic.config.home-manager.users.higorprado.home.path`
- `nix eval --raw path:$PWD#nixosConfigurations.predator-dendritic.config.home-manager.users.higorprado.programs.git.enable`
- `nix eval --raw path:$PWD#nixosConfigurations.predator-dendritic.config.home-manager.users.higorprado.programs.starship.enable`
- `nix store diff-closures $(nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path) $(nix build --no-link --print-out-paths path:$PWD#nixosConfigurations.predator-dendritic.config.home-manager.users.higorprado.home.path)`

Diff expectation:
- HM closure and major HM behaviors converge toward parity
- any remaining diff should be explainable feature-by-feature

Commit target:
- `refactor(home-manager): replace den mutual routing with local derivation`

### Phase 5: Migrate Host-Aware Parametric Features

Targets:
- features currently using `den.lib.parametric`, `den.lib.perHost`,
  `den.lib.take.*`

Changes:
- replace `den` context helpers with repo-owned context options available inside
  lower-level NixOS/HM modules
- migrate tricky modules first in isolated slices:
  - [modules/features/dev/llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix)
  - [modules/features/shell/fish.nix](/home/higorprado/nixos/modules/features/shell/fish.nix)
  - [modules/features/system/ssh.nix](/home/higorprado/nixos/modules/features/system/ssh.nix)
  - [modules/features/system/keyrs.nix](/home/higorprado/nixos/modules/features/system/keyrs.nix)
  - [modules/features/core/nix-settings.nix](/home/higorprado/nixos/modules/features/core/nix-settings.nix)
  - the former `user-context` shim
  - [modules/features/desktop/niri.nix](/home/higorprado/nixos/modules/features/desktop/niri.nix)
  - [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)

Validation:
- evaluate and build both shadow hosts after each migrated slice
- use `nix store diff-closures` for system and HM outputs on `predator`
- verify selected option-level parity for host-aware features

Diff expectation:
- removal of `den` helpers from migrated files
- preserved behavior through repo-owned context options

Commit target:
- `refactor(features): replace den parametric context with local context options`

### Phase 6: Switch Authoritative Outputs and Remove Den

Targets:
- [flake.nix](/home/higorprado/nixos/flake.nix)
- [modules/den.nix](/home/higorprado/nixos/modules/den.nix)
- any remaining `den` references under `modules/`

Changes:
- promote the shadow dendritic outputs to the canonical
  `nixosConfigurations.<host>` names
- remove `den` and `flake-aspects` inputs
- delete [modules/den.nix](/home/higorprado/nixos/modules/den.nix)
- remove any leftover dual-publish compatibility code

Validation:
- `./scripts/run-validation-gates.sh`
- `./scripts/check-repo-public-safety.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- final `nix store diff-closures` comparisons against the last known good `den`
  generation for both `predator` system/HM and `aurelius` system

Diff expectation:
- canonical outputs are now framework-local and `den`-free
- any remaining closure difference is intentional and documented

Commit target:
- `refactor(flake): remove den and switch to local dendritic framework`

### Phase 7: Rewrite Tooling, Fixtures, and Docs

Targets:
- `scripts/`
- `tests/fixtures/new-host-skeleton/`
- `docs/for-humans/`
- `docs/for-agents/`

Changes:
- rewrite generators, gates, and fixtures that currently assume:
  - `den.hosts`
  - `den.aspects`
  - `den.lib.perHost` / `perUser`
  - `provides.to-users` / `_.to-users`
- update docs so they describe the repo-local framework and dendritic pattern
  directly instead of describing `den`
- preserve the same ownership and safety rules where still valid

Validation:
- `./scripts/run-validation-gates.sh`
- `./scripts/check-docs-drift.sh`
- targeted script tests under `tests/`

Diff expectation:
- docs and tooling match the new architecture
- no lingering tracked references to `den` outside archival material

Commit target:
- `refactor(tooling): remove den assumptions from scripts and docs`

## Risks

- The largest technical risk is replacing host-to-user HM routing without
  falling back to ad hoc host wiring or `extraSpecialArgs`.
- The largest process risk is trying to remove `den` in one jump. The repo
  needs shadow outputs and parity checks first.
- Dual-publishing old and new surfaces during migration can create confusion if
  shadow output names and ownership are not explicit.
- Feature files that currently rely on `den` context helpers can easily regress
  if repo-local context options are not introduced before migrating them.
- Tooling drift is non-trivial: scripts, fixtures, and docs currently teach and
  enforce the `den` model, not a generic dendritic one.
- A partial migration that removes `den` syntax but keeps `den` semantics
  reimplemented piecemeal in host files would be architectural regression.

## Definition of Done

- No tracked active code path depends on `den` or `flake-aspects`.
- The repo remains dendritic in the strict sense:
  every non-entry-point Nix file is a top-level module, and lower-level modules
  are declared from top-level configuration rather than injected through
  `specialArgs`.
- `predator` and `aurelius` evaluate and build successfully through the new
  framework.
- System and HM outputs have parity with the pre-migration baseline, or every
  intentional difference is documented and accepted.
- Tooling, fixtures, and docs describe and validate the repo-local framework.
