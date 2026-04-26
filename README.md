# NixOS Configuration Repository

This repository contains the declarative NixOS + Home Manager setup for the
tracked hosts `predator`, `aurelius`, and `cerebelo`.

## What This Repo Is

This is the source of truth for:
1. System configuration (`hardware/`, `modules/`, `flake.nix`)
2. User environment (`modules/users/`, `private/users/`, `config/`)
3. Configuration payload files consumed by modules (`config/`)
4. Custom packages (`pkgs/`)
5. Operational scripts (`scripts/`)

The goal is reproducible, explicit, and maintainable configuration with clear ownership boundaries.

## Runtime Status

This repo now uses a repo-local dendritic runtime on top of `flake-parts`.
It no longer depends on `den` for host composition, user routing, or feature
publication.
The repo stopped using `den` because the upstream is still at `v0`, surface API
changes are still expected, there is not yet a strong deprecation or
compatibility guarantee, and recent routing changes caused regressions and
migration churn in this repo.

## Repo Shape

1. `hardware/`: machine-specific files only
2. `modules/features/`: reusable feature owners
3. `modules/desktops/`: concrete desktop compositions
4. `modules/hosts/`: concrete host owner files
5. `modules/nixos.nix`, `modules/flake-parts.nix`, `modules/users/`: structural runtime surfaces
6. `config/`, `pkgs/`, `lib/`, `scripts/`, `tests/`, `docs/`: payloads, helpers, tooling, and docs

## Host Model

1. Desktop hosts select their desktop by importing a concrete composition module (e.g. `config.flake.modules.nixos.desktop-hyprland-standalone`) in the host's explicit configuration module alongside the individual feature modules.
2. `predator` currently uses the Hyprland standalone composition.
3. `aurelius` and `cerebelo` are tracked server hosts.

## Documentation

1. Main docs index: `docs/README.md`
2. Human start point: `docs/for-humans/00-start-here.md`
3. Agent start point: `docs/for-agents/000-operating-rules.md`

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
