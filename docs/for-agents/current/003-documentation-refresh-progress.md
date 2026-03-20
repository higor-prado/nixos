# Documentation Refresh Progress

## Status

In progress

## Related Plan

- [003-documentation-refresh-after-den.md](/home/higorprado/nixos/docs/for-agents/plans/003-documentation-refresh-after-den.md)

## Baseline

- Canonical runtime is already `den`-free in active `.nix` code.
- `rg -n "\\bden\\b" --glob '*.nix' .` returns no tracked `.nix` matches.
- Remaining `den` references are concentrated in historical docs, migration
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

- Tightened the header and framing of
  [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md)
  so it is explicitly historical and no longer implies there is a shrinking
  live compatibility layer.

Validation:
- `./scripts/check-docs-drift.sh`

Commit:
- pending

## Final State

- Open: refresh the remaining living docs/tooling descriptions and decide what
  to archive vs keep as historical context.
