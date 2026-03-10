# User Bridge and Host Metadata Progress

Date: 2026-03-10
Status: closed after phase 7; phase 8 intentionally deferred

Plan:
- `docs/for-agents/plans/010-user-bridge-and-host-metadata-plan.md`

## Baseline

Current live bridge consumers in tracked feature/hardware code:
- `system-base.nix`
- `docker.nix`
- `bluetooth.nix`
- `keyrs.nix`
- `laptop-acer.nix`
- `nix-settings.nix`
- `niri.nix`
- `dms.nix`

Current bridge owner:
- `modules/features/user-context.nix`

Baseline host metadata split at the start of this work:
- `den.hosts` owned host membership and system
- `hardware/*/default.nix` owned `networking.hostName` and `custom.host.role`
- `hardware/host-descriptors.nix` owned script-only `integrations`

Current runtime smoke status:
- tracked under `scripts/`
- predator-only semantics
- outside canonical gate runner

Baseline authority table:

| Concern | Current authority | Notes |
|--------|-------------------|-------|
| tracked host membership | `den.hosts.<system>.<host>.users` | real source of tracked user identity |
| compatibility primary username | `custom.user.name` via `user-context.nix` | derived by default from the sole tracked host user |
| user OS/HM identity | `den._.define-user` | already den-native |
| admin groups | `den._.primary-user` plus repo-specific extra groups | still partly split because some features add groups through `custom.user.name` |
| runtime host role | `hardware/<host>/default.nix` via `custom.host.role` | explicit runtime contract signal |
| host integrations metadata | `hardware/host-descriptors.nix` | script-only metadata |
| hostname | host attr name + `networking.hostName` in `hardware/<host>/default.nix` | duplicated at baseline |

Phase 0 validation snapshot:

- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name` -> `higorprado`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name` -> `higorprado`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.host.role` -> `desktop`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.host.role` -> `server`
- `/tmp/user-bridge-before-system` -> `/nix/store/rgwb0x7mxia0ky0kp0xwh2498kdrk18w-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-before-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`

Phase 0 note:
- `./scripts/run-validation-gates.sh predator` was started as part of the baseline capture and left running into the next slice because it performs a full build; no baseline failure was observed before Phase 1 work began.

## Phase Checklist

- [x] Phase 0: baseline and authority table
- [x] Phase 1: migrate easy user-scoped consumers off `custom.user.name`
- [x] Phase 2: migrate `nix-settings` trusted-users
- [x] Phase 3: add narrow primary-tracked-user helper
- [x] Phase 4: migrate `niri` and `dms`
- [x] Phase 5: narrow `custom.user.name` to compatibility scope
- [x] Phase 6: deduplicate hostname ownership with den battery
- [x] Phase 7: clarify host role / descriptors contract
- [ ] Phase 8: decide runtime smoke boundary

## Notes

- This tracker intentionally distinguishes:
  - removing tracked feature dependence on `custom.user.name`
  - narrowing the bridge contract
  - deleting the bridge entirely
- The current plan aims for the first two, not automatic full bridge deletion.
- This file is now a historical closeout log for phases 0-7. It is no longer an
  active current-state diagnosis.

## Phase 1 Result

Files migrated off `custom.user.name`:
- `modules/features/system-base.nix`
- `modules/features/docker.nix`
- `modules/features/bluetooth.nix`
- `modules/features/keyrs.nix`
- `hardware/predator/hardware/laptop-acer.nix`
- `modules/hosts/predator.nix`

Implementation notes:
- user-scoped groups now come from den `{ host, user }` context instead of one compatibility username string
- `linuwu_sense` membership moved out of the hardware module and into the `predator` host aspect, because the hardware module does not receive den context
- `modules/features/system-base.nix` no longer owns the compatibility-bridge assertion; narrowing that contract is deferred to the later bridge-specific phase

Post-phase validation snapshot:
- `rg -n "custom\\.user\\.name" modules/features hardware/predator/hardware modules/hosts/predator.nix`
  now returns only:
  - `modules/features/user-context.nix`
  - `modules/features/nix-settings.nix`
  - `modules/features/niri.nix`
  - `modules/features/dms.nix`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
  -> `["linuwu_sense","wheel","networkmanager","video","audio","input","rfkill","docker","uinput"]`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
  -> `["wheel","networkmanager","video","audio","input","rfkill"]`
- `/tmp/user-bridge-phase1-system` -> `/nix/store/h3nyynm0if750fi9kxha8i58kjpwz7d0-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase1-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-before-system /tmp/user-bridge-phase1-system` -> empty
- `nix store diff-closures /tmp/user-bridge-before-hm /tmp/user-bridge-phase1-hm` -> empty
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass

## Phase 2 Result

Files migrated off `custom.user.name`:
- `modules/features/nix-settings.nix`

Implementation notes:
- `nix.settings.trusted-users` is now derived from `builtins.attrNames host.users`
- the setting is forced at the NixOS layer to avoid merging with the implicit NixOS default `root`
- the bridge no longer participates in `trusted-users`

Post-phase validation snapshot:
- `rg -n "custom\\.user\\.name" modules/features`
  now returns only:
  - `modules/features/user-context.nix`
  - `modules/features/niri.nix`
  - `modules/features/dms.nix`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.nix.settings.trusted-users`
  -> `["root","higorprado"]`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.nix.settings.trusted-users`
  -> `["root","higorprado"]`
- `/tmp/user-bridge-phase2-system` -> `/nix/store/lyrc62392i0cix5dbwixxdqbvgx6r3js-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase2-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-phase1-system /tmp/user-bridge-phase2-system` -> empty
- `nix store diff-closures /tmp/user-bridge-phase1-hm /tmp/user-bridge-phase2-hm` -> empty
- `./scripts/run-validation-gates.sh structure` -> pass

## Phase 3 Result

Files added:
- `lib/primary-tracked-user.nix`

Implementation notes:
- the helper exposes:
  - `trackedUserNames`
  - `primaryTrackedUserName`
- it asserts exactly one tracked host user and throws otherwise
- it is intentionally a plain helper in `lib`, not a new `custom.*` bridge

Post-phase validation snapshot:
- `/tmp/user-bridge-phase3-system` -> `/nix/store/dk83vs54h2471jz0ilmz0kxn1jd881px-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase3-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-phase2-system /tmp/user-bridge-phase3-system` -> empty
- `nix store diff-closures /tmp/user-bridge-phase2-hm /tmp/user-bridge-phase3-hm` -> empty
- `./scripts/run-validation-gates.sh structure` -> pass

## Phase 4 Result

Files migrated off `custom.user.name`:
- `modules/features/niri.nix`
- `modules/features/dms.nix`

Implementation notes:
- both modules now resolve the selected tracked host user through `lib/primary-tracked-user.nix`
- `niri` now derives the non-standalone session user from the helper
- `dms` now derives `greeter.configHome` from the helper via `config.users.users.<name>.home`
- `greetd.settings.default_session.user` still evaluates to `greeter` on `predator`, which confirms the DMS path remains the final owner in the non-standalone session flow

Post-phase validation snapshot:
- `rg -n "custom\\.user\\.name" modules/features`
  now returns only:
  - `modules/features/user-context.nix`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.services.greetd.settings.default_session.user`
  -> `greeter`
- `nix eval --raw --impure --expr 'let cfg = (builtins.getFlake "path:$PWD").nixosConfigurations.predator.config; in cfg.programs.dank-material-shell.greeter.configHome'`
  -> `/home/<tracked-user>`
- `/tmp/user-bridge-phase4-system` -> `/nix/store/64vv458dllkavrzx5g59z7clh5finwdd-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase4-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-phase3-system /tmp/user-bridge-phase4-system` -> empty
- `nix store diff-closures /tmp/user-bridge-phase3-hm /tmp/user-bridge-phase4-hm` -> empty
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass

## Phase 5 Result

Files narrowed to compatibility-only wording/ownership:
- `modules/features/user-context.nix`
- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/004-private-safety.md`
- `docs/for-humans/04-private-overrides.md`
- `docs/for-humans/workflows/105-private-overrides.md`
- `hardware/aurelius/private.nix.example`

Implementation notes:
- `modules/features/user-context.nix` now describes `custom.user.name` explicitly as a compatibility bridge
- the bridge owner now also enforces the unsafe-value assertion (`""`, `"user"`, `"root"`)
- operating docs no longer describe `custom.user.name` as the normal tracked feature wiring path
- private override docs/examples still keep the bridge as the lower-level compatibility selector

Post-phase validation snapshot:
- `./scripts/check-config-contracts.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `/tmp/user-bridge-phase5-system` -> `/nix/store/11nvz1vcqnn9ccinbq1cqmaj7n2gpnnw-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase5-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-phase4-system /tmp/user-bridge-phase5-system` -> empty
- `nix store diff-closures /tmp/user-bridge-phase4-hm /tmp/user-bridge-phase5-hm` -> empty

## Phase 6 Result

Files migrated to `den._.hostname`:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `hardware/predator/default.nix`
- `hardware/aurelius/default.nix`

Implementation notes:
- both host aspects now include `den._.hostname`
- manual `networking.hostName = "<host>"` assignments were removed from hardware defaults
- the repo now relies on den’s default `host.hostName = host.name` behavior

Post-phase validation snapshot:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.networking.hostName`
  -> `predator`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.networking.hostName`
  -> `aurelius`
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `/tmp/user-bridge-phase6-system` -> `/nix/store/nr48nyjlnnr5j6q7fqj3kaad8rdikpm1-nixos-system-predator-26.05.20260308.9dcb002`
- `/tmp/user-bridge-phase6-hm` -> `/nix/store/5899pf4l539g71wcxbfj0kigdk47rmmp-home-manager-path`
- `nix store diff-closures /tmp/user-bridge-phase5-system /tmp/user-bridge-phase6-system` -> empty
- `nix store diff-closures /tmp/user-bridge-phase5-hm /tmp/user-bridge-phase6-hm` -> empty

## Phase 7 Result

Files clarified:
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/004-antipattern-priority-order.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-humans/03-multi-host.md`

Clarification outcome:
- host metadata is no longer tracked as an accidental duplication problem
- the deliberate ownership split is now:
  - `den._.hostname` for hostname
  - `custom.host.role` for runtime role contract
  - `hardware/host-descriptors.nix` for script-only integrations metadata
- the remaining architectural backlog now focuses on:
  - runtime smoke boundary
  - the residual `custom.user.name` compatibility bridge

## Closeout

This tracker is complete for its executed scope.
The repo no longer treats hostname ownership as an active duplication problem.
The only intentionally deferred item from the original plan is the workflow
decision around `check-runtime-smoke.sh`.
