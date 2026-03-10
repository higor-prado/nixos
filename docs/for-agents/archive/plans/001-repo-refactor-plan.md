# Repo Refactor Plan

Date: 2026-03-09
Owner: Codex + user

## Goal

Improve maintainability and extensibility by reducing cross-layer coupling,
aligning tracked contracts with real repo state, and shrinking unnecessary
validation complexity.

## Execution Rules

Each slice must end with:

1. Code change
2. Structural validation
3. Eval/build validation
4. Before/after diff review
5. Commit

Preferred diff workflow:

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-before
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-before

# apply change

nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-after
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-after

nix run nixpkgs#nvd -- diff /tmp/predator-before /tmp/predator-after
nix run nixpkgs#nvd -- diff /tmp/hm-before /tmp/hm-after
```

## Phase 1

Decouple base user config from optional features and hardware.

Targets:

- `modules/features/system-base.nix`
- `modules/features/docker.nix`
- `modules/features/keyrs.nix`
- `hardware/predator/hardware/laptop-acer.nix`

Changes:

- Keep only truly base groups in `system-base`
- Move `docker` group ownership into `docker.nix`
- Move `uinput` and `rfkill` ownership next to the feature or hardware that needs them
- Move `linuwu_sense` group ownership into Acer hardware ownership

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-config-contracts.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix run nixpkgs#nvd -- diff ...`

Commit:

- `refactor: move optional user groups out of system-base`

## Phase 2

Split networking into base vs discovery/desktop policy.

Targets:

- `modules/features/networking.nix`
- `modules/hosts/aurelius.nix`
- new feature files for base/discovery policy if needed

Changes:

- Create a smaller shared networking baseline
- Move `resolved` and `avahi` into opt-in features
- Remove server-side `mkForce` undoing where possible

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`
- `./scripts/run-validation-gates.sh aurelius`
- `nix run nixpkgs#nvd -- diff ...`

Commit:

- `refactor: split networking base from discovery policy`

## Phase 3

Align public-safe contract with tracked repo state.

Targets:

- `modules/users/higorprado.nix`
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/004-private-safety.md`
- `scripts/check-repo-public-safety.sh`

Decision:

- either make tracked state satisfy public-safe rules
- or narrow the public-safe contract to match the actual repo model

Validation:

- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Commit:

- `docs+safety: align public-safe contract with tracked config`

## Phase 4

Reduce validation/tooling maintenance cost.

Targets:

- `scripts/`
- `scripts/lib/`
- `tests/scripts/`

Changes:

- Inventory scripts by regression class
- Merge near-duplicates
- Delete low-signal or redundant checks
- Keep one clear entrypoint per validation category

Validation:

- `tests/scripts/*.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`
- `./scripts/report-maintainability-kpis.sh`

Commit strategy:

- use multiple commits, not one bulk commit

## Priorities

1. Phase 1
2. Phase 2
3. Phase 3
4. Phase 4
