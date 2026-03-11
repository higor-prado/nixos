# DMS HM Migration Progress

## Status

In progress

## Related Plan

- [021-dms-hm-migration-plan.md](/home/higorprado/nixos/docs/for-agents/plans/021-dms-hm-migration-plan.md)

## Baseline

- `dms` runtime was owned from the NixOS side in the repo.
- Upstream Home Manager owns the DMS user runtime more cleanly.
- `dms-awww` is a custom wallpaper integration and remains a separate concern.
- The persist/disk work is paused until this startup path is repaired.

## Slices

### Slice 1

- converted research into an execution plan
- separated:
  - official DMS HM migration
  - custom `dms-awww` repair
  - `@persist` work

### Slice 2

- moved tracked `dms` ownership to the den `.homeManager` path in
  [dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)
- kept only system/greeter concerns on the NixOS side
- validation:
  - `./scripts/run-validation-gates.sh structure`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.dms.Service`
- confirmed evaluated HM `dms` service:
  - `ExecStart = dms run --session`
  - `Environment = [ ]`

### Slice 3

- repaired the custom `dms-awww` integration without PATH hacks in the unit
- extracted the runtime call into
  [run-dms-awww.sh](/home/higorprado/nixos/config/apps/dms/run-dms-awww.sh)
- wrapped the custom binary with runtime inputs via `writeShellApplication`
- added the explicit writable path required by theme generation:
  - `%h/.config/DankMaterialShell`
- validation:
  - `./scripts/run-validation-gates.sh structure`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.systemd.user.services.dms-awww.Service`
- confirmed evaluated HM `dms-awww` service:
  - `ExecStart = run-dms-awww`
  - no unit-local `PATH` override
  - `ReadWritePaths` includes `%h/.config/DankMaterialShell`

## Pending Runtime Validation

- apply the tracked config locally on `predator` with:
  - `nh os test path:$PWD`
- then verify:
  - `systemctl --user status dms.service --no-pager`
  - `systemctl --user status dms-awww.service --no-pager`
  - `journalctl --user -b --no-pager | rg "dms|awww|qs|matugen"`

## Final State

- build/eval validation is green
- runtime confirmation is still pending
