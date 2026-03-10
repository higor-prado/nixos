# ConditionUser and Battery Migration Progress

Date: 2026-03-09
Status: completed

Plan:
- `docs/for-agents/plans/006-conditionuser-and-batteries-plan.md`

## Scope

Tracked phases:
1. baseline and authority capture
2. desktop composition `ConditionUser` migration
3. remaining feature-level `ConditionUser` migration
4. `primary-user` battery adoption
5. `define-user` evaluation / adoption decision
6. docs and closeout

## Baseline

Status: captured

- `./scripts/run-validation-gates.sh structure` -> pass
- baseline system closure: `/tmp/conditionuser-before-system`
- baseline HM closure: `/tmp/conditionuser-before-hm`
- `predator.config.custom.user.name` -> `higorprado`
- `predator.config.users.users.higorprado.home` -> `$HOME`
- live `ConditionUser` values before migration:
  - `xdg-desktop-portal` -> `higorprado`
  - `xdg-desktop-portal-gtk` -> `higorprado`
  - `xdg-desktop-portal-gnome` -> `higorprado`
  - `dsearch` -> `higorprado`
- live portal PATH overrides before migration:
  - `xdg-desktop-portal` -> `["PATH=%h/.nix-profile/bin:%h/.local-state/nix/profile/bin:/etc/profiles/per-user/%u/bin:/nix/profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"]`
  - `xdg-desktop-portal-gtk` -> same as above
  - `xdg-desktop-portal-gnome` -> same as above

## Phase Checklist

### Phase 0: Baseline and Authority Capture

Status: completed

### Phase 1: Migrate Desktop Composition `ConditionUser` Ownership

Status: completed

Files changed:
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`

Result:
- removed NixOS-side `ConditionUser`/`Environment` ownership for:
  - `xdg-desktop-portal`
  - `xdg-desktop-portal-gtk`
- replaced that with HM-managed user drop-ins:
  - `systemd/user/xdg-desktop-portal.service.d/override.conf`
  - `systemd/user/xdg-desktop-portal-gtk.service.d/override.conf`

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `/tmp/conditionuser-phase1-system` built
- `/tmp/conditionuser-phase1-hm` built
- HM drop-in text eval:
  - `portal` -> `[Service]\\nEnvironment=PATH=...`
  - `portalGtk` -> `[Service]\\nEnvironment=PATH=...`

Diff review:
- system closure diff: empty
- HM closure diff:
  - `hm_systemduserxdgdesktopportal.service.doverride.conf: ∅ → ε`
  - `hm_systemduserxdgdesktopportalgtk.service.doverride.conf: ∅ → ε`
  - `unit-xdg-desktop-portal.service: ε → ∅`
  - `unit-xdg-desktop-portal-gtk.service: ε → ∅`

Interpretation:
- ownership moved from system-managed user units to HM-managed user drop-ins
- the PATH override payload stayed the same

### Phase 2: Migrate Remaining Feature-level `ConditionUser` Services

Status: completed

Files changed:
- `modules/features/niri.nix`
- `modules/features/dms.nix`

Result:
- removed NixOS-side `ConditionUser`/`Environment` ownership for
  `xdg-desktop-portal-gnome`
- added HM-managed user drop-in:
  - `systemd/user/xdg-desktop-portal-gnome.service.d/override.conf`
- removed the tracked `ConditionUser` filter from `dsearch`

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `/tmp/conditionuser-phase2-system` built
- `/tmp/conditionuser-phase2-hm` built
- ownership eval:
  - `gnomePortalDropin` -> `[Service]\\nEnvironment=PATH=...`
  - `hasDsearchConditionUser` -> `false`
  - `hasGnomePortalService` -> `false`

Diff review:
- system closure diff: empty
- HM closure diff:
  - `hm_systemduserxdgdesktopportalgnome.service.doverride.conf: ∅ → ε`
  - `unit-xdg-desktop-portal-gnome.service: ε → ∅`

Interpretation:
- the last portal PATH override moved to HM ownership
- `dsearch` no longer depends on the username compatibility bridge

### Phase 3: Adopt `den._.primary-user`

Status: completed

Files changed:
- `modules/users/higorprado.nix`
- `modules/features/system-base.nix`

Result:
- added `den._.primary-user` to the canonical tracked user aspect
- removed duplicated ownership of:
  - `isNormalUser`
  - `wheel`
  - `networkmanager`
  from `system-base`
- kept repo-specific common groups in `system-base`:
  - `video`
  - `audio`
  - `input`

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-config-contracts.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `/tmp/conditionuser-phase3-system` built
- `/tmp/conditionuser-phase3-hm` built
- evaluated user state:
  - `predatorNormal` -> `true`
  - `aureliusNormal` -> `true`
  - `predator.extraGroups` -> `["linuwu_sense","wheel","networkmanager","video","audio","input","rfkill","docker","uinput"]`
  - `aurelius.extraGroups` -> `["wheel","networkmanager","video","audio","input","rfkill"]`

Diff review:
- system closure diff: empty
- HM closure diff: empty

Interpretation:
- ownership moved to the battery without changing resulting user state
- this slice is a pure authority cleanup

### Phase 4: Evaluate `den._.define-user`

Status: completed

Files changed:
- `modules/users/higorprado.nix`

Result:
- adopted `den._.define-user` for the canonical tracked user aspect
- removed duplicated local ownership of:
  - `users.users.higorprado.home`
  - `home.username`
- kept repo-local ownership only for:
  - primary group wiring
  - HM `stateVersion`
  - private HM imports

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `/tmp/conditionuser-phase4-system` built
- `/tmp/conditionuser-phase4-hm` built
- evaluated wiring:
  - `predatorHome` -> `$HOME`
  - `aureliusHome` -> `$HOME`
  - `hmUser` -> `higorprado`
  - `hmHome` -> `$HOME`

Diff review:
- system closure diff: empty
- HM closure diff: empty

Decision:
- `define-user` was a net win and was adopted
- it removed duplication without introducing new special cases

### Phase 5: Docs and Closeout

Status: completed

Files changed:
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/004-private-safety.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/plans/006-conditionuser-and-batteries-plan.md`

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `/tmp/conditionuser-final-system` built
- `/tmp/conditionuser-final-hm` built

Diff review:
- final system closure diff vs Phase 4: empty
- final HM closure diff vs Phase 4: empty

Closeout:
- no live `ConditionUser = config.custom.user.name` remains in tracked code
- the canonical tracked user aspect now uses:
  - `define-user`
  - `primary-user`
  - `user-shell`
- living docs now describe the post-migration ownership model
