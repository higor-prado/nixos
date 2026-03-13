# Den Alignment Follow-ups Progress

## Status

Completed

## Related Plan

- [030-den-alignment-follow-ups-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/030-den-alignment-follow-ups-plan.md)

## Baseline

- The den alignment audit is recorded in [032-den-pattern-alignment-report.md](/home/higorprado/nixos/docs/for-agents/archive/log-tracks/032-den-pattern-alignment-report.md).
- The active issues to address are:
  - `predator`'s tracked `linuwu_sense` user-group wiring does not appear in the evaluated `extraGroups`
  - two living agent docs still over-prefer den `{ host, user }` context instead of the narrowest correct context shape
- No fixes have been applied for this follow-up yet.

## Slices

### Slice 1

- Created the active execution plan and matching progress log for the den alignment follow-up.
- Captured the intended fix split: one code slice for `linuwu_sense`, one docs slice for living guidance.

Validation:
- scaffold/doc review only

Diff result:
- active plan/log docs only

Commit:
- pending

### Slice 2

- Re-baselined the reported `predator` group issue and confirmed the tracked inline host include was not affecting the evaluated user group list.
- While tracing the failure, confirmed the same owner-pattern problem also affected other host-side user-group snippets in:
  - [modules/features/core/system-base.nix](/home/higorprado/nixos/modules/features/core/system-base.nix)
  - [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
  - [modules/features/system/bluetooth.nix](/home/higorprado/nixos/modules/features/system/bluetooth.nix)
  - [modules/features/system/keyrs.nix](/home/higorprado/nixos/modules/features/system/keyrs.nix)
  - [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- Moved the intended `predator` user-group wiring into the tracked user aspect at [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix), where den's current `{ host, user }` user context applies it reliably.
- Removed the now-confirmed inert host-side `extraGroups` snippets from the affected feature/host modules.

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff result:
- `predator` now evaluates with:
  - `["video","audio","input","docker","rfkill","uinput","linuwu_sense","wheel","networkmanager"]`
- the dead host-side user-group snippets are removed

Commit:
- pending

### Slice 3

- Updated the two living agent docs that still said to prefer den `{ host, user }` generally:
  - [docs/for-agents/000-operating-rules.md](/home/higorprado/nixos/docs/for-agents/000-operating-rules.md)
  - [docs/for-agents/003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md)
- Reworded both to prefer the narrowest correct den context shape:
  - owned `homeManager` when no host/user data is needed
  - `{ host }` for host-aware logic
  - `{ host, user }` only when the logic is genuinely user-specific

Validation:
- `./scripts/check-docs-drift.sh`

Diff result:
- living agent guidance now matches the den-alignment report and current repo guidance

Commit:
- pending

### Slice 4

- Ran the final validation and safety checks after the code and docs follow-ups.

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Diff result:
- all requested follow-up changes validated successfully
- non-blocking warnings remained the same:
  - `system.stateVersion` warning in one validation path
  - `xorg.libxcb` deprecation warning

Commit:
- pending

## Final State

- The `predator` tracked user now evaluates with the intended feature/host groups, including `linuwu_sense`.
- The ineffective host-side user-group snippets that were relying on the wrong den owner/context pattern were removed.
- The two living agent docs now teach the narrowest correct den context shape instead of over-preferring `{ host, user }`.
- Public-safety, docs-drift, and the full validation gate runner passed after the follow-up.
