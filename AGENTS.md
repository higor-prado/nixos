# Agent Quick Guide

## First Reads
1. `docs/for-agents/000-operating-rules.md`
2. `docs/for-agents/001-repo-map.md`
3. `docs/for-agents/002-architecture.md`
4. `docs/for-agents/003-module-ownership.md`
5. `docs/for-agents/004-private-safety.md`
6. `docs/for-agents/005-validation-gates.md`
7. `docs/for-agents/006-extensibility.md`
8. `docs/for-agents/007-option-migrations.md`
9. `docs/for-agents/999-lessons-learned.md`

## Agent Docs Organization Rule
1. Root (`docs/for-agents/`) is only for critical operating docs (numbered 000–009 and 999).
2. Non-trivial work must be document-driven:
   - read the relevant operating rules and repo map before executing,
   - validate after each meaningful slice.

## Docs Naming Rule
1. Agent docs use three-digit prefix NNN-name.md.
2. Keep numbering stable and consistent when adding files.

## Safety Rules
1. Never commit real private override files under `private/users/` or `private/hosts/`; only `*.example` should be tracked.
2. Run public safety gate before publish:
   - `./scripts/check-repo-public-safety.sh`
3. Run mandatory Nix validation gates after meaningful changes:
   - `nix flake metadata`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
   - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.stateVersion`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
   - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

## Script Boundary
1. Repo `scripts/` is for shared validation/safety tooling.
2. Private/host-specific ops scripts live outside the repo at:
   - `~/ops/nixos-private-scripts/bin`

## Mutable Config Note
1. Some files are provisioned as mutable copy-once configs (for example `dms`).
2. Parity checks can fail when local runtime files intentionally diverge from templates.
