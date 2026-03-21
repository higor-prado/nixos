# Remove Non-Dendritic Option Surfaces

## Goal

Remove top-level/runtime surfaces that do not belong in a dendritic-first repo,
especially anything in `modules/options/` that exists as local framework glue,
transport, pseudo-contract bookkeeping, or script-oriented inventory instead of
structural composition or a narrow semantic fact.

## Scope

In scope:
- `modules/options/repo-runtime-contracts.nix`
- `modules/options/inventory.nix`
- concrete host files under `modules/hosts/`
- tracked scripts/tests/docs that still depend on those surfaces
- removal of dead aliases and dead schema that survive only by inertia

Out of scope:
- changing host feature selections
- reworking hardware split
- cosmetic file renames unless they reduce real complexity
- `flake.lock`

## Current State

- The dendritic reference in `~/git/dendritic` has only two relevant top-level
  option surfaces in the example:
  - `options.username`
  - `options.configurations.nixos.*.module`
- The repo still carries extra local surfaces that are not part of that shape:
  - `modules/options/repo-runtime-contracts.nix`
  - `modules/options/inventory.nix`
- `modules/options/repo-runtime-contracts.nix` currently mixes:
  - `custom.host.role`
  - `custom.user.name`
  - shared HM Catppuccin wiring
- `modules/options/inventory.nix` currently mixes:
  - a legitimate `username` fact
  - `repo.hosts.*` schema for script/runtime metadata
- `custom.host.role` is already assigned in `hardware/<host>/default.nix`, so
  the option declaration is separate from the real owner.
- `custom.user.name` currently exists as a selected-user bridge even though the
  repo now also has `username`.
- `repo.hosts.*.name` appears to be dead schema.
- `scripts/check-desktop-composition-matrix.sh` still uses synthetic
  declarations and `specialArgs`, which is acceptable only if it is clearly a
  test harness and not teaching the runtime shape.

## Desired End State

- `modules/options/` contains only surfaces that match the dendritic reference
  or are strictly justified by a real repo need.
- `repo-runtime-contracts.nix` is either deleted or reduced to the smallest
  possible surface that still has a concrete, defensible reason to exist.
- `inventory.nix` is either deleted or reduced to the smallest possible shape
  that cannot be replaced by simpler top-level facts or direct concrete host
  composition.
- No option exists only to help scripts if the same fact can be read from:
  - concrete host modules,
  - concrete `nixosConfigurations`,
  - hardware defaults,
  - or a single narrow top-level fact.
- No dead schema fields remain.

## Phases

### Phase 0: Prove Necessity Before Preserving Anything

Targets:
- `modules/options/repo-runtime-contracts.nix`
- `modules/options/inventory.nix`
- all tracked consumers of:
  - `custom.host.role`
  - `custom.user.name`
  - `repo.hosts.*`
  - `username`

Changes:
- none yet
- produce a usage map for each remaining option
- classify each one as:
  - structural
  - narrow semantic fact
  - script-only convenience
  - dead schema
  - artificial bridge

Validation:
- `rg -n 'custom\\.host\\.role|custom\\.user\\.name|repo\\.hosts\\.|\\busername\\b' modules scripts tests docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans`
- `rg -n '^\\s*options\\.' modules/options modules/features`

Diff expectation:
- none

Commit target:
- none

### Phase 1: Remove Dead and Redundant Schema

Targets:
- `modules/options/inventory.nix`
- any tracked docs/tests/scripts that mention removed fields

Changes:
- remove `repo.hosts.<name>.name` if it truly has no consumer
- remove any other host inventory field that is not read by real tracked code
- keep `username` only if it continues to be the narrow top-level user fact

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `rg -n 'repo\\.hosts\\.[^.]+\\.name' .`

Diff expectation:
- less schema, no runtime behavior change

Commit target:
- `refactor(options): drop dead inventory schema`

### Phase 2: Eliminate `custom.user.name` If `username` Can Own The Meaning

Targets:
- `modules/options/repo-runtime-contracts.nix`
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/dms.nix`
- host modules, scripts, tests, and docs that consume `custom.user.name`

Changes:
- replace tracked consumers of `config.custom.user.name` with the top-level
  `config.username` fact where the dendritic reference pattern supports it
- move script reads away from lower-level `config.custom.user.name` if the same
  fact can be read from the top-level flake evaluation
- if a private host-specific username override is still a real requirement, do
  not preserve `custom.user.name` automatically:
  - first design the smallest dendritic-compatible override path
  - otherwise delete the bridge

Validation:
- `./scripts/check-config-contracts.sh`
- `./scripts/run-validation-gates.sh all`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- selected-user meaning owned by one fact, not two

Commit target:
- `refactor(options): remove selected-user bridge`

### Phase 3: Eliminate `custom.host.role` Option Declaration If It Is Purely Script-Facing

Targets:
- `modules/options/repo-runtime-contracts.nix`
- hardware host defaults
- scripts using `custom.host.role`
- docs that describe role ownership

Changes:
- verify whether scripts can continue reading `config.custom.host.role` from the
  concrete NixOS config without a dedicated top-level declaration module
- if yes, delete the declaration from `repo-runtime-contracts.nix`
- if no, document exactly why the option declaration is still required and keep
  only that, not the current mixed bag
- never duplicate the assignment in host composition

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh all`

Diff expectation:
- role contract either disappears cleanly or is justified explicitly as the
  smallest necessary remainder

Commit target:
- `refactor(options): remove host-role contract surface`

### Phase 4: Delete `repo-runtime-contracts.nix` Or Reduce It To One Honest Purpose

Targets:
- `modules/options/repo-runtime-contracts.nix`
- Catppuccin shared HM wiring owner

Changes:
- if both `custom.host.role` and `custom.user.name` are gone, delete
  `repo-runtime-contracts.nix`
- move `home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ]`
  into an owner that actually matches that concern
- if one narrow option truly remains, rename/reframe the file around that single
  concern instead of keeping a “contracts” junk drawer

Validation:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- no mixed-purpose contract bag remains

Commit target:
- `refactor(options): remove artificial contract layer`

### Phase 5: Re-Evaluate Whether `repo.hosts.*` Should Exist At All

Targets:
- `modules/options/inventory.nix`
- `modules/hosts/*.nix`
- `modules/features/core/nix-settings.nix`
- script helpers that read `repo.hosts.*`

Changes:
- challenge each remaining use of `repo.hosts.*`
- replace with simpler sources where possible:
  - local host `let` bindings in concrete host modules
  - `config.username`
  - concrete config state
  - hardware descriptors for script-only topology
- only keep `repo.hosts.*` if it still buys something concrete that the
  reference pattern does not already provide more simply

Validation:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-extension-contracts.sh`
- `./scripts/check-config-contracts.sh`

Diff expectation:
- either `repo.hosts.*` shrinks to a clearly justified minimum or disappears

Commit target:
- `refactor(options): remove host inventory layer`

## Risks

- Removing `custom.user.name` may expose a real but currently implicit private
  override requirement.
- Removing `repo.hosts.*` too aggressively could break script topology checks if
  they are not first redirected to concrete sources.
- The desktop matrix harness may need its own cleanup slice to stop teaching
  the wrong pattern while still validating compositions.

## Definition of Done

- `modules/options/` contains only surfaces that are clearly defensible under
  the dendritic reference.
- no dead schema fields remain.
- no “contract” or “inventory” layer survives merely because it was convenient
  during migration.
- every surviving `mkOption` in the active runtime can be explained as either:
  - structural, or
  - a narrow semantic fact with a real owner.
- `./scripts/run-validation-gates.sh all` passes.
