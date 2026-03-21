# Structural Dendritic Alignment

## Goal

Remove the remaining structural leftovers that still drift from the `dendritic`
reference in `~/git/dendritic`, without inventing new framework surface or
moving junk from one place to another.

## Scope

In scope:
- `modules/options/configurations-nixos.nix`
- `modules/options/inventory.nix`
- `modules/users/higorprado.nix`
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- `hardware/host-descriptors.nix`
- docs/tests/scripts that still depend on the surfaces above

Out of scope:
- feature behavior changes unrelated to structure
- reintroducing any repo-local carrier, contract, or pseudo-inventory
- `flake.lock`

## Current State

- `modules/options/configurations-nixos.nix` is structurally legitimate, but it
  still exports `flake.dendritic`, which does not appear in the `dendritic`
  reference and has no active consumer in the repo.
- `modules/options/inventory.nix` no longer contains inventory; it only defines
  `options.username`, which matches the `dendritic` reference, but the file name
  and concept are stale.
- `modules/users/higorprado.nix` hardcodes `userName = "higorprado"` while the
  top-level fact `username` also defaults to `"higorprado"`, creating duplicate
  identity state.
- `modules/desktops/dms-on-niri.nix` and
  `modules/desktops/niri-standalone.nix` still express composition through
  indirect `imports = [ ({ ... }: { ... }) { ... } ]` patterns that are more
  ceremonial than the reference.
- `hardware/host-descriptors.nix` is not runtime, but it is still a script-side
  metadata surface that must justify its existence rather than surviving by
  inertia.

## Desired End State

- No dead compatibility alias remains in the flake outputs.
- The file that defines `username` is named and documented according to what it
  really is.
- There is one clear source of truth for the tracked username in runtime code.
- Desktop composition files are direct and readable, without unnecessary nested
  import ceremony.
- `hardware/host-descriptors.nix` either remains as narrowly justified
  script-side metadata or is removed entirely if it no longer carries distinct
  value.

## Phases

### Phase 0: Baseline and Consumer Audit

Targets:
- `modules/options/configurations-nixos.nix`
- `modules/options/inventory.nix`
- `modules/users/higorprado.nix`
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- `hardware/host-descriptors.nix`

Changes:
- none
- prove active consumers for:
  - `flake.dendritic`
  - `inventory.nix`
  - `hardware/host-descriptors.nix`
- map every place that still duplicates the tracked username

Validation:
- `rg -n "\\bflake\\.dendritic\\b|\\bdendritic\\b" . --glob '!docs/for-agents/archive/**' --glob '!flake.lock'`
- `rg -n "\\busername\\b|userName = \\\"higorprado\\\"" modules docs scripts tests`
- `rg -n "host-descriptors" . --glob '!docs/for-agents/archive/**'`

Diff expectation:
- no code changes yet

### Phase 1: Remove the Dead Flake Alias

Targets:
- `modules/options/configurations-nixos.nix`
- consumers/docs/tests if any exist

Changes:
- delete `flake.dendritic` if the Phase 0 audit confirms it is dead
- keep only the canonical `flake.nixosConfigurations` and `flake.checks`

Validation:
- `nix flake metadata path:$PWD`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- smaller flake output surface
- no runtime behavior change

Commit target:
- `refactor(runtime): remove dead flake dendritic alias`

### Phase 2: Replace the Stale `inventory.nix` Name and Unify Username Ownership

Targets:
- `modules/options/inventory.nix`
- `modules/users/higorprado.nix`
- docs/tests/scripts that reference the old path or duplicate the username fact

Changes:
- rename `modules/options/inventory.nix` to a name that matches the reference
  and its real contents, preferably `modules/options/meta.nix`
- stop duplicating the tracked username in user-owned runtime code; consume the
  top-level `config.username` fact instead
- update docs/tests/scripts to reference the new file path

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix eval .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.username`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`

Diff expectation:
- one top-level username fact
- no stale "inventory" naming in active runtime docs

Commit target:
- `refactor(runtime): align username fact with dendritic meta pattern`

### Phase 3: Simplify Desktop Composition Modules

Targets:
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- human docs if they still teach the old indirect form

Changes:
- rewrite the lower-level composition modules to set values directly instead of
  using indirect `imports = [ ({ ... }: { ... }) { ... } ]` ceremony
- keep composition explicit and local to the host-facing desktop module

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- same evaluated behavior
- more direct desktop composition code

Commit target:
- `refactor(desktops): simplify dendritic desktop compositions`

### Phase 4: Re-justify or Remove `hardware/host-descriptors.nix`

Targets:
- `hardware/host-descriptors.nix`
- `scripts/check-dendritic-host-onboarding-contracts.sh`
- `scripts/check-extension-contracts.sh`
- `scripts/new-host-skeleton.sh`
- related fixture tests/docs

Changes:
- prove whether `hardware/host-descriptors.nix` still protects a distinct shared
  script contract
- if yes, shrink it to the smallest useful metadata surface and document why it
  exists
- if no, remove it and inline/derive the needed facts at the script boundary

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/check-dendritic-host-onboarding-contracts.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `bash tests/scripts/dendritic-host-onboarding-contracts-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- script-side metadata either becomes narrower and justified or disappears

Commit target:
- `refactor(validation): justify or remove host descriptor metadata`

### Phase 5: Final Sweep

Targets:
- living docs
- runner/docs registry entries
- remaining references to stale structural names

Changes:
- update active docs to match the cleaned structure
- ensure no active docs still describe:
  - `inventory.nix`
  - `flake.dendritic`
  - indirect desktop composition ceremony

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- runtime and docs describe the same shape

Commit target:
- `docs(runtime): align structural docs with cleaned dendritic shape`

## Risks

- `flake.dendritic` may still be used by an overlooked local workflow; Phase 0
  must prove that it is dead before removal.
- `hardware/host-descriptors.nix` may still carry real value for script
  onboarding contracts; do not delete it without proving that the checks remain
  meaningful.
- Username unification can ripple into docs/tests if any path still assumes the
  old duplicated source of truth.

## Definition of Done

- No dead `flake.dendritic` alias remains.
- No active file in `modules/options/` is misnamed around the old “inventory”
  concept.
- Runtime code has a single clear tracked-username fact.
- Desktop compositions are materially simpler and still pass validation.
- `hardware/host-descriptors.nix` is either clearly justified and narrow or gone.
