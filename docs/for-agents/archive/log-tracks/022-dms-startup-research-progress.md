# DMS Startup Research Progress

## Status

In progress

## Related Plan

- [020-dms-startup-research-plan.md](/home/higorprado/nixos/docs/for-agents/plans/020-dms-startup-research-plan.md)

## Baseline

- `predator` hit a startup regression after unrelated experimental work on the
  `impermanence-study` branch.
- Boot logs showed:
  - `dms.service` failed because `qs` was not found
  - `dms-awww.service` failed because `awww` was not found
- A later manual DMS start exposed an additional write issue for
  `~/.config/DankMaterialShell`.

## Slices

### Slice 1: Initial diagnosis

- Confirmed that `dms` and `dms-awww` are distinct concerns.
- Confirmed that the repo had been treating them too closely during the first
  fix attempt.
- Confirmed from upstream DMS sources:
  - NixOS module clears the `dms` service path
  - Home Manager module owns the user-facing runtime more cleanly

### Slice 2: Reverted bad local attempts

- Reverted the local experimental edits made to `modules/features/desktop/dms.nix`.
- Reverted the local experimental edits made to
  `modules/features/desktop/dms-wallpaper.nix`.
- Removed the temporary uncommitted wrapper/script attempt.

### Slice 3: Corrected direction

- Captured the current conclusion:
  - `dms` should be reconsidered from the Home Manager ownership path
  - `dms-awww` should be fixed separately as a custom integration
- No further code changes made yet.

## Final State

- research state is preserved
- no DMS code changes are pending in the worktree
- next step is a proper migration/fix plan before touching code again
