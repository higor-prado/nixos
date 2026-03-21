# Remove Script-Side Host Descriptors

## Goal

Remove parallel host metadata and any remaining layout drift that
exists only to help tooling, so scripts derive what they need from the real repo
structure instead of requiring parallel metadata.

## Scope

In scope:
- `scripts/check-extension-contracts.sh`
- `scripts/new-host-skeleton.sh`
- related fixture tests/docs/registry entries
- final alignment of root-level runtime surface paths (`modules/nixos.nix`,
  `modules/flake-parts.nix`, tracked user owner)

Out of scope:
- feature behavior changes
- reintroducing any inventory/descriptor file elsewhere
- `flake.lock`

## Current State

- Runtime structure is now close to the `dendritic` reference:
  - tracked user owner carrying `username`
  - `modules/nixos.nix`
  - `modules/flake-parts.nix`
- Parallel host metadata is not used by the runtime.
- The file still exists only because some scripts read:
  - host names
  - script-side integration flags such as `disko` / `homeManager`
- `lib/` is not empty; it still contains `mutable-copy.nix` and `_helpers.nix`,
  both with live runtime consumers.
- There is no active `framework/` directory in the repo.

## Desired End State

- No script requires parallel host metadata.
- Shared validation/onboarding scripts derive host names and integration facts
  from the real repo structure or from explicit file-presence checks.
- No parallel host metadata file remains.
- Active docs describe the root-level runtime surfaces directly and stop
  teaching `modules/options/` as a conceptual bucket.

## Phases

### Phase 0: Baseline and Dependency Audit

Targets:
- the script consumers
- related fixture tests/docs

Changes:
- none
- prove exactly what each script reads from the parallel metadata layer
- classify each consumed fact as:
  - derivable from runtime/source tree
  - still needing an explicit script contract

Validation:
- `rg -n "host-descriptors" scripts tests docs --glob '!docs/for-agents/archive/**'`
- `sed -n '1,260p' scripts/check-extension-contracts.sh`
- `sed -n '1,240p' scripts/new-host-skeleton.sh`

Diff expectation:
- no code changes yet

### Phase 1: Replace Host Name Discovery With Source-of-Truth Derivation

Targets:
- `scripts/check-extension-contracts.sh`
- `scripts/lib/extension_contracts_eval.sh`

Changes:
- derive tracked host names from the real repo source of truth, not a descriptor
  file
- prefer the narrowest honest source:
  - `modules/hosts/*.nix`
  - `hardware/*/default.nix`
  - or `configurations.nixos.*` via eval if that is cleaner and stable

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `refactor(validation): derive tracked hosts from repo source of truth`

### Phase 2: Remove Descriptor-Based Integration Flags

Targets:
- `scripts/new-host-skeleton.sh`
- related fixture tests

Changes:
- stop requiring checked-in parallel metadata for onboarding
- express onboarding contracts in terms of real files and explicit generated
  host composition shape
- derive integration facts from file presence or concrete imports instead of
  static flags in a separate metadata file

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `refactor(validation): remove descriptor-driven host onboarding`

### Phase 3: Delete the Parallel Host Metadata Layer

Targets:
- any remaining references in scripts/docs/fixtures/registry

Changes:
- delete the file and dead consumers
- delete or update every remaining consumer
- keep only checks that still protect a distinct invariant after the deletion

Validation:
- `rg -n "host-descriptors|check-dendritic-host-onboarding-contracts|dendritic-host-onboarding-contracts" scripts tests docs --glob '!docs/for-agents/archive/**'`
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh all`

Commit target:
- `refactor(validation): remove script-side host descriptor file`

### Phase 4: Final Layout/Docs Sweep

Targets:
- `README.md`
- `docs/for-agents/*.md`
- `docs/for-humans/*.md`
- any live references to `modules/options/` as a conceptual runtime bucket

Changes:
- align docs with the final root-level runtime surface layout
- keep `lib/` documented as two live helpers, not dead structure
- explicitly note that no `framework/` directory exists anymore

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `docs(runtime): align docs with descriptor-free runtime layout`

## Risks

- Some script-side integration facts may be harder to derive cleanly than host
  names; do not replace a small explicit contract with grep-driven garbage.
- Onboarding fixture tests may need a different shape once the descriptor file
  is gone.
- The right source of truth for host discovery must stay explicit and stable,
  not “whatever happens to exist on disk”.

## Definition of Done

- No parallel host metadata file remains.
- No active script or doc depends on parallel host descriptor metadata.
- Host discovery and onboarding checks use the real repo structure.
- Root-level runtime surface docs are aligned and `modules/options/` is no
  longer treated as a conceptual framework bucket.
