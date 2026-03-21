# Test Harness Cleanup

## Goal

Remove or simplify test/validation harness code that survives only by creating
synthetic structure, while keeping the runtime aligned to the dendritic
reference in `~/git/dendritic`.

## Scope

In scope:
- `scripts/check-desktop-composition-matrix.sh`
- `scripts/check-extension-simulations.sh`
- `scripts/check-feature-role-conditionals.sh`
- associated fixtures/tests/docs/registry entries

Out of scope:
- runtime feature behavior changes
- new top-level option surfaces
- reintroducing script-only metadata into runtime Nix code
- `flake.lock`

## Current Findings

### 1. `check-desktop-composition-matrix.sh` is the ugliest remaining harness

It still creates a synthetic `lib.nixosSystem` with:
- `specialArgs`
- inline `mkOption`
- fake host/user state (`desktop-matrix`, `fixture-user`)

This no longer pollutes the runtime, but the harness itself is still not in the
spirit of the dendritic pattern.

### 2. `check-extension-simulations.sh` has weak signal

It now only proves that `extendModules` on `aurelius` still evaluates to a
valid `systemDrv`. That may still be useful, but it is close to redundant with
real eval/build gates.

### 3. `check-feature-role-conditionals.sh` is stale in wording and targeting

It still references `custom.host.role`, which no longer exists in the runtime.
The useful invariant is broader: feature files must not reintroduce role-driven
conditional logic in place of explicit host composition.

### 4. The runtime `.nix` code is now much cleaner

Active `mkOption` usage in tracked runtime code is now down to:
- `modules/options/inventory.nix`
- `modules/options/configurations-nixos.nix`
- `modules/features/desktop/niri.nix`

That is materially closer to the dendritic reference.

## Desired End State

- No synthetic test harness creates structure that looks like runtime policy
  unless that structure is the narrowest way to test a real invariant.
- No test script forces the runtime to expose fields or option surfaces just so
  the test can read them.
- Structure checks use either:
  - concrete host configs,
  - published lower-level modules,
  - or bounded test fixtures that do not teach the wrong architecture.
- Guardrail scripts use names/messages that match the current runtime.

## Phases

### Phase 0: Audit Signal vs Noise

Targets:
- `scripts/check-desktop-composition-matrix.sh`
- `scripts/check-extension-simulations.sh`
- `scripts/check-feature-role-conditionals.sh`

Changes:
- none
- classify each script as:
  - keep as-is
  - simplify
  - rename/reword
  - delete

Validation:
- `sed -n '1,220p' scripts/check-desktop-composition-matrix.sh`
- `sed -n '1,160p' scripts/check-extension-simulations.sh`
- `sed -n '1,80p' scripts/check-feature-role-conditionals.sh`

### Phase 1: Replace the Desktop Matrix Synthetic System If Possible

Targets:
- `scripts/check-desktop-composition-matrix.sh`
- docs/tests that describe it

Changes:
- prefer validating desktop compositions through:
  - published lower-level composition modules plus minimal bounded fixtures, or
  - concrete host selection plus declared composition topology
- remove `specialArgs` and inline `mkOption` if a cleaner shape can express the
  same invariant
- if a bounded synthetic fixture is still necessary, keep it obviously test-only
  and as small as possible

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `refactor(validation): simplify desktop composition matrix harness`

### Phase 2: Re-evaluate Extension Simulation

Targets:
- `scripts/check-extension-simulations.sh`
- runner/docs/registry entries

Changes:
- delete it if it no longer catches a distinct failure mode
- otherwise reduce it to the smallest real assertion

Validation:
- `./scripts/check-extension-simulations.sh`
- `./scripts/run-validation-gates.sh all`

Commit target:
- `refactor(validation): prune weak extension simulation harness`

### Phase 3: Rename or Broaden the Stale Role Guardrail

Targets:
- `scripts/check-feature-role-conditionals.sh`
- registry/docs references

Changes:
- stop talking about `custom.host.role`
- either:
  - rename the script to a broader “no role conditionals in features” check, or
  - delete it if the invariant is no longer worth enforcing directly

Validation:
- `./scripts/check-feature-role-conditionals.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `refactor(validation): align stale role guardrail with runtime`

### Phase 4: Final Sweep

Targets:
- `scripts/`
- `tests/`
- living docs

Changes:
- remove dead registry entries, stale descriptions, and fixture language
- ensure no harness still teaches old runtime surfaces

Validation:
- `./scripts/check-docs-drift.sh`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `./scripts/run-validation-gates.sh all`

Commit target:
- `refactor(validation): align harness docs and fixtures`
