# Agent Docs Den Post-Bidirectional Update Progress

## Status

Completed

## Related Plan

- [004-agent-docs-den-post-bidirectional-update.md](/home/higorprado/nixos/docs/for-agents/plans/004-agent-docs-den-post-bidirectional-update.md)

## Baseline

- [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md) still described the removed upstream `hm-os` / `hm-integration` split.
- [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md) and [006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md) still used host-aware HM examples with `{ host, user, ... }` where `{ host, ... }` is the better guidance.
- [999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md) did not yet record the March 13, 2026 den context-width shift.

## Slices

### Slice 1

- Updated [002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md) to describe the current upstream `home-manager.nix` behavior instead of the removed internal file split.
- Added the explicit post-March-13 note that host-to-user OS reentry is opt-in through `den._.bidirectional`.
- Narrowed the host-aware HM example from `{ host, user, ... }` to `{ host, ... }`.
- Validation run:
  - manual reread only
- Diff result:
  - active den architecture guidance now matches the current repo and upstream behavior
- Commit:
  - pending

### Slice 2

- Updated [006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md) so the feature-with-home-manager example uses `{ host, ... }`.
- Added a short note that `{ host, user, ... }` should only be used when the logic is truly user-specific.
- Added lesson 34 to [999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md) to preserve the March 13 den change as a durable repo rule.
- Validation run:
  - pending docs drift check
- Diff result:
  - active operating docs now teach the same narrowed context model used in tracked code
- Commit:
  - pending

## Final State

- Active agent docs no longer teach the stale HM integration internals.
- Active examples now prefer the narrowest context shape for host-aware HM guidance.
- The March 13 den change is now preserved as an explicit repo lesson.
