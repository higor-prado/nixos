# Final Structural Cleanups

## Goal

Remove the remaining low-signal structural smells that survived the larger
dendritic migration, without inventing new abstraction or moving runtime logic
to please tooling.

## Scope

In scope:
- `scripts/check-option-declaration-boundary.sh`
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/dms.nix`
- `hardware/predator/overlays.nix` and its ownership/location
- living docs that describe these boundaries

Out of scope:
- `flake.lock`
- feature behavior changes
- new option surfaces
- new script-side metadata files

## Problems

### 1. User owner is hardcoded in the boundary script

Current shape:
- `scripts/check-option-declaration-boundary.sh` allows
  `modules/users/higorprado.nix` by exact path

Why this is bad:
- policy is expressed as one concrete filename, not as an ownership rule
- the script reflects the current user name, not the architectural intent

Desired shape:
- the boundary should allow the tracked user owner category, not one literal
  file path

### 2. `niri` and `dms` capture the whole outer `config`

Current shape:
- `modules/features/desktop/niri.nix` starts with `topConfig = config;`
- `modules/features/desktop/dms.nix` starts with `topConfig = config;`

Why this is bad:
- they capture the whole top-level config only to read `username`
- this is wider than necessary and obscures what data the owner actually needs

Desired shape:
- capture the narrow fact directly, e.g. `userName = config.username`, in the
  outer module scope
- no `topConfig = config` alias

### 3. `hardware/predator/overlays.nix` is semantically right enough, but named
### and placed loosely

Current shape:
- imported from `hardware/predator/default.nix`
- contains machine-specific nixpkgs overlays

What is good:
- it is host-scoped and lower-level, so it does not belong in shared feature
  owners unless the patch becomes reusable

What is bad:
- `overlays.nix` is generic and underspecified
- inside `hardware/`, the filename reads as a bucket rather than explicit
  intent

Decision rule:
- if the remaining overlay is truly predator-only, keep it under
  `hardware/predator/`
- rename only if that improves clarity materially, e.g. `nixpkgs-overlays.nix`
- do not move it into shared runtime or `pkgs/` unless multiple hosts/features
  genuinely need the same override

## Phases

### Phase 0: Baseline

Targets:
- `scripts/check-option-declaration-boundary.sh`
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/dms.nix`
- `hardware/predator/default.nix`
- `hardware/predator/overlays.nix`

Validation:
- `sed -n '1,220p' scripts/check-option-declaration-boundary.sh`
- `sed -n '1,200p' modules/features/desktop/niri.nix`
- `sed -n '1,200p' modules/features/desktop/dms.nix`
- `sed -n '1,200p' hardware/predator/default.nix`
- `sed -n '1,200p' hardware/predator/overlays.nix`

### Phase 1: Fix Boundary Policy

Targets:
- `scripts/check-option-declaration-boundary.sh`

Changes:
- replace the literal allowlist entry `modules/users/higorprado.nix`
  with an ownership-shaped rule, likely `modules/users/`
- keep the rule narrow enough to avoid allowing arbitrary option declarations

Validation:
- `./scripts/run-validation-gates.sh structure`

### Phase 2: Narrow Feature Inputs

Targets:
- `modules/features/desktop/niri.nix`
- `modules/features/desktop/dms.nix`

Changes:
- remove `topConfig = config`
- capture only `username` from the outer owner scope
- leave behavior unchanged

Validation:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Phase 3: Overlay Location Decision

Targets:
- `hardware/predator/default.nix`
- `hardware/predator/overlays.nix`

Changes:
- decide whether the current file stays where it is or gets renamed for clarity
- only rename if the new name is materially better
- do not create a new bucket

Validation:
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`

## Definition of Done

- option-boundary policy no longer names one concrete tracked user file
- `niri` and `dms` no longer capture the whole outer `config`
- overlay location is either explicitly justified or renamed to a clearer
  host-scoped filename
- no new generic infrastructure is introduced
