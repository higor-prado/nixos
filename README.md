# NixOS Configuration Repository

This repository contains the declarative NixOS + Home Manager setup for the
tracked hosts `predator` and `aurelius`.

## What This Repo Is

This is the source of truth for:
1. System configuration (`hardware/`, `modules/`, `flake.nix`)
2. User environment (`home/`)
3. Configuration payload files consumed by modules (`config/`)
4. Custom packages (`pkgs/`)
5. Operational scripts (`scripts/`)

The goal is reproducible, explicit, and maintainable configuration with clear ownership boundaries.

## Repository Structure

1. `flake.nix`: entrypoint and wiring
2. `hardware/`: host hardware configuration
3. `modules/features/`: feature owners (NixOS + home-manager fragments)
4. `modules/desktops/`: concrete desktop composition modules
5. `modules/hosts/`: host inventory and concrete host configurations
6. `modules/lib/`: repo/runtime internals
7. `home/base/`: gitignored private overrides
8. `lib/`: generic helper functions used by tracked modules
9. `config/`: app/config payload files and helper payloads
10. `pkgs/`: custom derivations
11. `scripts/`: helper and verification scripts
12. `docs/`: durable docs plus active/archived execution docs

## Host Role Model

1. `custom.host.role = "desktop" | "server"` is a validation contract signal set in `hardware/<name>/default.nix`; it is consumed by validation scripts but must not be used as a conditional in module code.
2. Desktop hosts select their desktop by importing a concrete composition module (e.g. `config.flake.modules.nixos.desktop-dms-on-niri`) in the host's explicit configuration module alongside the individual feature modules.
3. `aurelius` is the tracked server host.

## Documentation

1. Human workflows and explanations:
   - start: `docs/for-humans/00-start-here.md`
   - workflows: `docs/for-humans/workflows/101-switch-and-rollback.md`
2. Agent operations and contracts:
   - start: `docs/for-agents/000-operating-rules.md`
   - repo map: `docs/for-agents/001-repo-map.md`
   - active execution docs: `docs/for-agents/plans/`, `docs/for-agents/current/`
   - archived execution docs: `docs/for-agents/archive/`

## Validation Commands

1. Fast feedback:
   - `./scripts/check-changed-files-quality.sh [origin/main]`
   - `./scripts/run-validation-gates.sh structure`
2. Full required validation before a major push or branch update:
   - `./scripts/run-validation-gates.sh all`
3. Desktop runtime smoke (when relevant):
   - `./scripts/check-runtime-smoke.sh --allow-non-graphical`

## CI

1. CI workflow: `.github/workflows/validate.yml`
2. Default push/PR lane: `lint-structure`
3. Docs-only lane: `docs-drift-only`
4. Heavy eval/build lanes are manual-dispatch + schedule controlled.
