# Documentation Refresh Progress

## Status

Completed

## Related Plan

- [003-documentation-refresh.md](/home/higorprado/nixos/docs/for-agents/plans/003-documentation-refresh.md)

## Baseline

- Canonical runtime is already free of the removed framework in active `.nix` code.
- `rg -n "\\bden\\b" --glob '*.nix' .` returns no tracked `.nix` matches.
- Remaining historical references are concentrated in migration docs, migration
  logs, and a few living descriptions/indexes.

## Slices

### Slice 1

- Identified the first stale living references and refreshed:
  - [01-philosophy.md](/home/higorprado/nixos/docs/for-humans/01-philosophy.md)
  - [999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md)
  - [shared-script-registry.tsv](/home/higorprado/nixos/tests/pyramid/shared-script-registry.tsv)
- Recorded the Fish regression fix and the active-reference audit in the active
  migration log.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Commit:
- `51952bf` `refactor(docs): prune stale den references`

### Slice 2

- Replaced the old architecture document with the current runtime guide at
  [002-architecture.md](/home/higorprado/nixos/docs/for-agents/002-architecture.md).
- Updated onboarding surfaces (`AGENTS.md`, `README.md`, `docs/README.md`,
  docs-drift targets, and public-safety allowlist) to the new architecture
  path and current dendritic terminology.
- Archived completed migration execution docs that no longer belong on the
  active surface.

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Commit:
- pending

## Final State

- Living docs now describe the active repo directly in dendritic terms.
- The old migration runtime no longer appears in the live onboarding surface.
- Completed migration execution docs were moved out of `plans/` and `current/`
  into the archive.
