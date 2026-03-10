# Agent Docs Archive And Reconciliation Progress

## Status

Completed.

## Related Plan

- `docs/for-agents/plans/017-agent-docs-archive-and-reconciliation-plan.md`

## Baseline

Created in this slice:
- `docs/for-agents/archive/plans/`
- `docs/for-agents/archive/log-tracks/`
- `docs/for-agents/plans/000-plan-scaffold.md`
- `docs/for-agents/current/000-log-track-scaffold.md`

Initial findings captured for cleanup:
- `999-lessons-learned.md` still contains outdated migration-registry and old
  validation-surface lessons
- `001-repo-map.md` still refers to an `AI` bucket that no longer matches the
  feature tree
- some human docs still carry stale wording from older host/LLM transitions

## Completed Slices

### Slice 1: active-surface cleanup

- added archive-aware rules to `000-operating-rules.md`
- updated `001-repo-map.md` to match the live feature tree and archive surface
- updated `docs/README.md` to explain active vs archived execution docs
- refreshed `workflows/103-add-host.md` to match the current skeleton shape
- pruned `999-lessons-learned.md` to lessons that still match the live repo

Validation:
- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`

### Slice 2: archive closed execution records

- moved closed plans from `docs/for-agents/plans/` to
  `docs/for-agents/archive/plans/`
- moved closed progress logs from `docs/for-agents/current/` to
  `docs/for-agents/archive/log-tracks/`
- kept only active operating/diagnostic docs plus the two scaffolds in the
  active surface

## Validation

- `./scripts/check-docs-drift.sh`
- `bash scripts/check-changed-files-quality.sh`

## Notes

- The archive surface is meant to reduce active-surface noise, not delete
  history.
- Scaffolds are intentionally simple and should stay that way.
