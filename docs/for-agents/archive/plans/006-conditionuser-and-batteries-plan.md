# ConditionUser and Battery Migration Plan

Date: 2026-03-09
Status: completed

## Current Repo State

This plan was written before the removal of tracked fake/example surface. The
current repo state now assumes:

- no `ops` user aspect
- no `admin` replacement user aspect
- no tracked example hosts (`server-example`, `new-host`)
- only real tracked hosts remain in validation topology:
  - `predator`
  - `aurelius`
- the host generator uses the canonical tracked `higorprado` user aspect by
  default

The execution below should be interpreted against that current state, not the
older fallback-user model.

## Goal

Finish the remaining user-scope cleanup by:

1. removing tracked `ConditionUser = config.custom.user.name` patterns where
   den/Home Manager ownership is the better fit
2. adopting den batteries where they are the clear owner of behavior
3. keeping the repo's public-personal constraints intact
4. validating every slice with closure diffs before commit

This plan is intentionally selective. It is not a "use all batteries" plan.
It is a "use batteries where they reduce local ownership and do not fight the
repo model" plan.

## Source Context

Repo files:
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`
- `modules/features/niri.nix`
- `modules/features/dms.nix`
- `modules/features/system-base.nix`
- `modules/features/user-context.nix`
- `modules/users/higorprado.nix`

Upstream references:
- ~/git/den/docs/src/content/docs/reference/batteries.mdx
- ~/git/den/docs/src/content/docs/guides/batteries.mdx
- ~/git/den/modules/aspects/provides/define-user.nix
- ~/git/den/modules/aspects/provides/primary-user.nix
- ~/git/den/modules/aspects/provides/user-shell.nix
- ~/git/den/modules/aspects/provides/hostname.nix
- ~/git/den/modules/aspects/provides/tty-autologin.nix
- ~/git/den/templates/ci/modules/features/user-host-bidirectional-config.nix
- ~/git/dendritic/README.md

## Problem Statement

The repo still has a mixed user-scope model:

- user services are sometimes declared in NixOS and filtered by
  `ConditionUser = config.custom.user.name`
- some user identity/base account logic still lives in repo-local modules even
  though den batteries already own that concern
- `custom.user.name` still exists as a compatibility bridge, so every migration
  must avoid breaking private overrides and existing host wiring

The current live `ConditionUser` surface is:

1. `modules/desktops/dms-on-niri.nix`
   - `xdg-desktop-portal`
   - `xdg-desktop-portal-gtk`
2. `modules/desktops/niri-standalone.nix`
   - `xdg-desktop-portal`
   - `xdg-desktop-portal-gtk`
3. `modules/features/niri.nix`
   - `xdg-desktop-portal-gnome`
4. `modules/features/dms.nix`
   - `dsearch`

These are all user services. The den-native direction is to let user-targeted
ownership flow through `.homeManager` or user-context dispatch, not to keep
declaring NixOS `systemd.user.services.*` and then filtering by username.

## Battery Suitability Matrix

### Batteries to adopt in this plan

1. `den._.primary-user`
   - Adopt for the canonical tracked primary user aspect
   - Candidate files:
     - `modules/users/higorprado.nix`
   - Why:
     - it already owns `isNormalUser`, `wheel`, and `networkmanager`
     - those are still duplicated in `modules/features/system-base.nix`

2. `den._.define-user`
   - Adopt only after the account-ownership slice is ready
   - Candidate files:
     - `modules/users/higorprado.nix`
   - Why:
     - it already owns `users.users.<name>.home`, `isNormalUser`, and
       Home Manager `home.username`/`home.homeDirectory`
   - Constraint:
     - the repo has a tracked concrete-home exception for `higorprado`, so the
       migration must keep public-safety allowlist behavior correct

### Batteries to leave unchanged in this plan

1. `den._.user-shell`
   - already adopted
   - no new work needed except preserving ownership

2. `den._.hostname`
   - not obviously a net win here
   - hostname currently lives coherently in hardware defaults
   - moving it now would create churn without reducing real complexity

3. `den._.tty-autologin`
   - not currently part of the tracked host behavior being refactored
   - do not expand scope unless a host already uses manual tty autologin logic

4. `den._.inputs'`, `den._.self'`
   - unrelated to the current user-scope cleanup

5. `den._.unfree`
   - separate package-policy concern

6. `den._.mutual-provider`, `den._.forward`, `den._.import-tree`
   - not needed for this migration

## Target Architecture

After this plan:

1. user services no longer rely on `ConditionUser = config.custom.user.name`
2. desktop composition files own desktop composition, not username filters
3. den batteries own user-account primitives where they are already better than
   repo-local code
4. `custom.user.name` remains only as a compatibility bridge for consumers that
   cannot yet move, not as the preferred owner of user identity
5. all slices preserve behavior, or any intentional closure changes are small
   and explicitly explained

## Non-goals

This plan does not:

- remove `custom.user.name` completely
- redesign private override shape
- migrate hostnames to `den._.hostname`
- adopt batteries just because they exist
- rewrite the entire user model in one commit

## Execution Order

1. Phase 0: capture baseline and authority snapshot
2. Phase 1: migrate desktop `ConditionUser` services to user-scoped HM ownership
3. Phase 2: migrate remaining feature-level `ConditionUser` services
4. Phase 3: adopt `den._.primary-user` where appropriate
5. Phase 4: evaluate and, if safe, adopt `den._.define-user`
6. Phase 5: docs, contracts, and closeout validation

The order is deliberate:
- first move the clearly user-scoped service ownership
- then reduce duplicated user-account primitives
- only then decide whether `define-user` is a net win

## Phase 0: Baseline and Authority Capture

Purpose:
- record the current live closure and service ownership before moving user
  services around
- capture exactly which options and units are present today

Required baselines:
- system closure baseline for `predator`
- HM closure baseline for `predator`
- eval snapshots for:
  - `predator.config.custom.user.name`
  - `predator.config.users.users.higorprado.home`
  - `predator.config.systemd.user.services.xdg-desktop-portal`
  - `predator.config.systemd.user.services.xdg-desktop-portal-gtk`
  - `predator.config.systemd.user.services.xdg-desktop-portal-gnome`
  - `predator.config.systemd.user.services.dsearch`

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-before-hm
nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name
nix eval --raw path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.home
nix eval --json path:$PWD#nixosConfigurations.predator.config.systemd.user.services.xdg-desktop-portal
nix eval --json path:$PWD#nixosConfigurations.predator.config.systemd.user.services.xdg-desktop-portal-gtk
nix eval --json path:$PWD#nixosConfigurations.predator.config.systemd.user.services.xdg-desktop-portal-gnome
nix eval --json path:$PWD#nixosConfigurations.predator.config.systemd.user.services.dsearch
```

Definition of done:
- progress log contains the exact baselines and intended authority table

Commit:
- no code commit required if this phase is documentation-only

## Phase 1: Migrate Desktop Composition `ConditionUser` Ownership

Scope:
- `modules/desktops/dms-on-niri.nix`
- `modules/desktops/niri-standalone.nix`

Current problem:
- both desktop composition files declare user services in NixOS and gate them
  with `ConditionUser = config.custom.user.name`

Target:
- keep the composition-specific host baseline in `.nixos`
- move the per-user service environment overrides into `.homeManager`
- remove the `ConditionUser` usage entirely from these two files

Recommended implementation:
1. keep in `.nixos`:
   - `services.greetd.enable`
   - `systemd.user.services.niri-flake-polkit.enable = false`
   - `xdg.portal.extraPortals`
   - composition parameterization like `custom.niri.standaloneSession`
2. move the `PATH=${portalExecPath}` user-service overrides into
   `.homeManager` `systemd.user.services.*`
3. use normal host-owned `.homeManager` ownership; do not reintroduce
   `_module.args.host` or any repo-local host bridge
4. preserve the mutable-copy `custom.kdl` provisioning in the same `.homeManager`
   block

Important check:
- confirm the relevant HM `systemd.user.services` structure can express the same
  environment override without relying on a NixOS `unitConfig.ConditionUser`

Validation:
```bash
./scripts/run-validation-gates.sh structure
bash tests/scripts/new-host-skeleton-fixture-test.sh
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-phase1-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-phase1-hm
nix store diff-closures /tmp/conditionuser-before-system /tmp/conditionuser-phase1-system
nix store diff-closures /tmp/conditionuser-before-hm /tmp/conditionuser-phase1-hm
```

Diff expectation:
- system closure may shrink slightly if ownership moves out of the host side
- HM closure may grow correspondingly
- the net change must be explainable as ownership relocation only

Commit target:
- `refactor: move desktop portal user services to hm ownership`

## Phase 2: Migrate Remaining Feature-level `ConditionUser` Services

Scope:
- `modules/features/niri.nix`
- `modules/features/dms.nix`

Current problem:
- these features still declare user services in NixOS and filter by username

Target:
- `xdg-desktop-portal-gnome` and `dsearch` user-service ownership becomes
  user-scoped
- `dms.nix` continues to own DMS program/greeter config, but not username
  filtering

Recommended implementation:
1. in `modules/features/niri.nix`:
   - keep NixOS ownership for greetd/niri/portal host settings
   - move the user-service `PATH` environment override for
     `xdg-desktop-portal-gnome` into `.homeManager`
2. in `modules/features/dms.nix`:
   - keep NixOS ownership for `programs.dsearch` and `programs.dank-material-shell`
   - move the `dsearch` user service override to `.homeManager` if the unit is
     user-scoped there
3. replace any remaining `/home/${userName}` style logic with canonical user
   home resolution where possible

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-phase2-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-phase2-hm
nix store diff-closures /tmp/conditionuser-phase1-system /tmp/conditionuser-phase2-system
nix store diff-closures /tmp/conditionuser-phase1-hm /tmp/conditionuser-phase2-hm
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.niri.enable
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.dank-material-shell.enable
```

Diff expectation:
- same rule as Phase 1: relocation, not behavior drift

Commit target:
- `refactor: remove remaining desktop conditionuser wiring`

## Phase 3: Adopt `den._.primary-user` for User-account Primitives

Scope:
- `modules/users/higorprado.nix`
- `modules/features/system-base.nix`

Current problem:
- `modules/features/system-base.nix`
  still owns `isNormalUser`, `wheel`, and `networkmanager` for the current user
- den already has a battery for that

Target:
- `den._.primary-user` becomes the owner of:
  - `isNormalUser`
  - `wheel`
  - `networkmanager`
- `system-base.nix` keeps only truly system-wide concerns

Recommended implementation:
1. add `den._.primary-user` to `modules/users/higorprado.nix`
2. remove the corresponding fields from `modules/features/system-base.nix`
3. keep repo-specific groups like `video`, `audio`, `input` only where they
   still make sense and are truly common

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-config-contracts.sh
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-phase3-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-phase3-hm
nix store diff-closures /tmp/conditionuser-phase2-system /tmp/conditionuser-phase3-system
nix store diff-closures /tmp/conditionuser-phase2-hm /tmp/conditionuser-phase3-hm
nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups
nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups
```

Diff expectation:
- ideally empty
- if group ordering changes but set membership is preserved, document it

Commit target:
- `refactor: move primary user primitives to den battery`

## Phase 4: Evaluate and Selectively Adopt `den._.define-user`

Scope:
- `modules/users/higorprado.nix`
- `modules/features/system-base.nix`
- `modules/features/user-context.nix`

This is an evaluation phase first, not an automatic migration.

Questions to answer before code lands:
1. Can `define-user` replace the repo-local `users.users.${userName}` creation
   in `system-base.nix` without breaking the public-repo exception for
   `higorprado`?
2. Does the repo still need `system-base` to create a tracked user from
   `custom.user.name`, or is that now fully superseded by user aspects and
   `den.hosts.<system>.<host>.users`?
3. Can the canonical tracked user aspect gain `define-user` cleanly without
   reintroducing duplicate ownership through `system-base`?

Decision rule:
- only adopt `define-user` if it removes ownership duplication without adding
  new special-case overrides
- if adopting it forces awkward overrides or complicates the private-safety
  model, keep the current explicit user-aspect shape and record the reason

If adoption is approved after evaluation:
1. add `den._.define-user` to the relevant user aspects
2. remove the duplicated user-creation logic from `system-base.nix`
3. keep only concrete overrides that are intentionally repo-specific
4. update docs/rules to say `define-user` is the owner of account creation

If adoption is rejected:
1. document the reason in:
   - `docs/for-agents/999-lessons-learned.md`
   - progress log
2. keep the repo-local user-definition ownership explicit

Validation if code changes:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-phase4-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-phase4-hm
nix store diff-closures /tmp/conditionuser-phase3-system /tmp/conditionuser-phase4-system
nix store diff-closures /tmp/conditionuser-phase3-hm /tmp/conditionuser-phase4-hm
nix eval --raw path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.home
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.home
```

Commit target:
- `refactor: adopt define-user for tracked user aspects`

or, if rejected:
- `docs: record define-user non-adoption rationale`

## Phase 5: Docs, Contracts, and Final Closeout

Purpose:
- align the living docs and contracts with the new ownership model

Files likely touched:
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/004-private-safety.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/007-antipattern-remediation-progress.md`

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/conditionuser-final-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/conditionuser-final-hm
nix store diff-closures /tmp/conditionuser-before-system /tmp/conditionuser-final-system
nix store diff-closures /tmp/conditionuser-before-hm /tmp/conditionuser-final-hm
```

Definition of done:
- no live `ConditionUser = config.custom.user.name` remains in tracked code
- batteries are adopted only where they are the clear owner
- docs describe the resulting ownership model
- any rejected battery adoption has an explicit rationale

Commit target:
- `docs: close conditionuser and battery migration`

## Mandatory Validation Discipline

Every code slice in this plan must follow this sequence:

1. build the relevant baseline output
2. make one logical change
3. run structural validation
4. build predator system and HM outputs
5. diff closures with the immediately previous baseline
6. inspect the diff and explain it in the progress log
7. commit only after the diff is understood

Core commands:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/<phase>-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/<phase>-hm
nix store diff-closures /tmp/<prev>-system /tmp/<phase>-system
nix store diff-closures /tmp/<prev>-hm /tmp/<phase>-hm
```

## Commit Strategy

Recommended commits:

1. `refactor: move desktop portal user services to hm ownership`
2. `refactor: remove remaining desktop conditionuser wiring`
3. `refactor: move primary user primitives to den battery`
4. one of:
   - `refactor: adopt define-user for tracked user aspects`
   - `docs: record define-user non-adoption rationale`
5. `docs: close conditionuser and battery migration`

## Risks

1. HM vs NixOS user-service semantics may not be 1:1.
   - Mitigation:
     - inspect resulting service definitions via `nix eval`
     - validate the closure diff and, if needed later, runtime-smoke locally on
       `predator`

2. `define-user` may fight the repo's tracked concrete-home exception.
   - Mitigation:
     - treat Phase 4 as evaluate-first
     - do not force adoption if it increases complexity

3. `higorprado`-specific tracked assumptions may not generalize cleanly if a
   future host introduces a second tracked user aspect.
   - Mitigation:
     - keep the `primary-user` decision explicit in the user aspect
     - do not turn the current personal-repo default into a hidden generic rule

4. docs may still describe the older compatibility bridge as preferred.
   - Mitigation:
     - close with a dedicated docs pass, not ad-hoc edits

## Success Criteria

This plan is successful when:

1. the tracked `ConditionUser` username bridge is gone from desktop/user
   services
2. the repo uses den batteries where they clearly reduce local ownership
3. the repo does not adopt batteries that create more indirection than value
4. each code slice has a clean validation story and a reviewed closure diff
