# Antipattern Remediation Plan

Date: 2026-03-09
Status: planned

Source diagnosis:
- `docs/for-agents/current/003-antipattern-diag.md`

Execution log:
- `docs/for-agents/current/007-antipattern-remediation-progress.md`

## Goal

Fix the live architectural antipatterns that remain after the `core-options`
refactor:

1. hybrid user model around `custom.user.name`
2. duplicated host-context transport (`den.schema.host` -> `config.host.*` -> HM `_module.args.host`)
3. synthetic `custom.<feature>.enable` validation signals
4. triplicated host metadata across descriptors, host modules, and hardware defaults
5. split shell ownership between den `user-shell` and repo `fish`
6. predator-scoped runtime smoke still exposed as a shared gate
7. desktop features deriving home paths from username strings

## Target Architecture

The refactor should converge on these ownership rules:

1. **Host system and host user membership are declared in `den.hosts`.**
   - `den.hosts.<system>.<name>` owns:
     - system architecture
     - host-scoped inputs/custom package context
     - tracked user membership/classes

2. **Concrete user aspects own concrete account identity.**
   - user aspects own concrete home/group/private imports
   - features should stop depending on a synthetic "current username" string

3. **Host/user context should flow through den contexts, not repo-local bridges.**
   - prefer den `{ host }` and `{ host, user }` parametric dispatch
   - remove repo-local bridge layers once consumers are migrated

4. **Validation should observe real configuration state, not synthetic mirrors.**
   - scripts should read actual NixOS/Home Manager options or one explicit
     topology registry
   - avoid dedicated `custom.<feature>.enable` signals unless a real config
     option does not exist and there is no better source

5. **Shared validation surface must stay genuinely shared.**
   - host-local or workstation-local smoke checks should not sit in the
     canonical shared gate interface

6. **Each host fact should have one authoritative owner.**
   - no script-enforced duplication where the repo can instead evaluate the
     authoritative source directly

## Non-goals

This plan is not about:
- pinning all personal custom package sources
- splitting `fish.nix` or `theme.nix` for LOC reasons alone
- broad CI redesign
- redesigning den itself

## Baseline Facts

Current confirmed live antipatterns:
- `custom.user.name` still drives user creation and multiple feature modules
- `config.host.*` still exists as a local bridge for `.nixos` consumers
- HM host context still arrives through `_module.args.host`
- validation still reads `custom.<feature>.enable`
- host role/system still exist in more than one source
- `check-runtime-smoke.sh` is still top-level shared tooling

Current likely authority candidates:
- `den.hosts.<system>.<name>` for system and host user membership
- concrete user aspects for concrete user identity
- hardware/default or host aspect only for facts that are real runtime config
- shared registry files only for script-only metadata that cannot be derived by eval

## Ordering

Recommended execution order:

1. Phase 0: baseline and authority capture
2. Phase 1: remove shared/runtime boundary ambiguity
3. Phase 2: remove synthetic feature-presence signals
4. Phase 3: unify shell ownership
5. Phase 4: collapse duplicated host metadata
6. Phase 5: migrate to den-native user ownership
7. Phase 6: remove repo-local host-context transport
8. Phase 7: clean desktop/home-path consumers and final docs

This order is deliberate:
- boundary cleanup and signal cleanup reduce validation noise first
- shell ownership is smaller and safer than user-model migration
- host metadata should be normalized before large user/context changes
- user-model migration must happen before removing `config.host`/`custom.user.name`
  from remaining feature code

## Phase 0: Baseline and Authority Capture

Purpose:
- record exact current behavior before structural changes
- write down which source becomes authoritative for each fact

Files:
- `docs/for-agents/current/007-antipattern-remediation-progress.md`
- possibly a small authority table update in `docs/for-agents/003-module-ownership.md` later, but not required in this phase

Required outputs:
- baseline system closure for `predator`
- baseline HM closure for `predator`
- baseline eval snapshots for:
  - `aurelius.config.custom.host.role`
  - `predator.config.custom.host.role`
  - `predator.config.custom.user.name`
  - `aurelius.config.custom.user.name`

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-before-hm
nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name
nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.host.role
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.host.role
```

Definition of done:
- progress log contains the baselines and phase checklist

## Phase 1: Remove Shared/Runtime Boundary Ambiguity

Antipatterns addressed:
- predator-scoped runtime smoke exposed as shared gate

Target architecture:
- `check-runtime-smoke.sh` is no longer part of the canonical shared gate
  surface under `run-validation-gates.sh`
- it either:
  - moves to `~/ops/nixos-private-scripts/bin`, or
  - stays in-repo as clearly non-canonical/local tooling not wired into the
    shared validation interface

Preferred implementation:
1. remove `runtime-smoke` from `scripts/run-validation-gates.sh`
2. remove it from shared validation docs and registries
3. if the script remains tracked, classify it as local/auxiliary only
4. keep usage docs pointing to the private ops location if you move it out

Files likely touched:
- `scripts/run-validation-gates.sh`
- `scripts/check-validation-source-of-truth.sh`
- `docs/for-agents/005-validation-gates.md`
- `tests/pyramid/shared-script-registry.tsv`
- `tests/scripts/run-validation-gates-fixture-test.sh`

Validation:
```bash
./scripts/run-validation-gates.sh structure
bash tests/scripts/run-validation-gates-fixture-test.sh
bash scripts/check-changed-files-quality.sh
./scripts/check-docs-drift.sh
```

Diff expectation:
- no system/HM closure change

Commit target:
- `refactor: remove runtime smoke from shared validation surface`

## Phase 2: Remove Synthetic Feature-Presence Signals

Antipatterns addressed:
- synthetic `custom.<feature>.enable` validation signals

Target architecture:
- scripts read real configuration state instead of `custom.<feature>.enable`
- `feature-presence-signals.nix` disappears once no consumer remains

Recommended implementation path:
1. build a mapping from each synthetic flag to a real observable config:
   - `custom.niri.enable` -> `programs.niri.enable`
   - `custom.dms.enable` -> `programs.dank-material-shell.enable`
   - `custom.fcitx5.enable` -> real input method config
   - `custom.gnomeKeyring.enable` -> real gnome-keyring option
   - `custom.dmsWallpaper.enable` -> real service/unit/config presence
   - `custom.nautilus.enable` -> real package/program/service state
2. update validation scripts to use those real signals
3. remove signal writes from feature modules
4. delete `modules/features/feature-presence-signals.nix`
5. remove it from host includes, templates, and fixtures

Important constraint:
- do not replace one synthetic signal with another under a new name
- if one feature truly has no durable real observable target, document the
  exception explicitly before keeping any synthetic signal

Files likely touched:
- `modules/features/feature-presence-signals.nix`
- feature modules currently writing `custom.<feature>.enable`
- `scripts/check-config-contracts.sh`
- `scripts/check-runtime-smoke.sh` if still tracked
- host templates and fixtures

Validation:
```bash
./scripts/check-config-contracts.sh
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase2-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase2-hm
nix store diff-closures /tmp/antipattern-before-system /tmp/antipattern-phase2-system
nix store diff-closures /tmp/antipattern-before-hm /tmp/antipattern-phase2-hm
```

Diff expectation:
- ideally empty closures; if not empty, every change must be explained as a move
  from synthetic to real state, not behavior drift

Commit target:
- `refactor: replace synthetic feature signals with real config checks`

## Phase 3: Unify Shell Ownership

Antipatterns addressed:
- split ownership between den `user-shell` and repo `fish`

Target architecture:
- den `user-shell` owns login shell assignment and shell enablement
- repo `fish` owns fish UX, abbreviations, interactive functions, theme
  integration, and other fish-specific behavior only

Recommended implementation:
1. remove user shell assignment from `modules/features/fish.nix`
2. keep `programs.fish` config in the owner that still makes sense after step 1
3. remove comments/documentation that describe precedence tricks
4. ensure hosts/users that need fish still get it through `den._.user-shell "fish"`

Files likely touched:
- `modules/features/fish.nix`
- `modules/users/higorprado.nix`
- docs mentioning shell precedence

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase3-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase3-hm
nix store diff-closures /tmp/antipattern-phase2-system /tmp/antipattern-phase3-system
nix store diff-closures /tmp/antipattern-phase2-hm /tmp/antipattern-phase3-hm
nix eval --json path:$PWD#nixosConfigurations.predator.config.programs.fish.enable
```

Diff expectation:
- empty or trivially explainable

Commit target:
- `refactor: make den user-shell the sole shell owner`

## Phase 4: Collapse Duplicated Host Metadata

Antipatterns addressed:
- triplicated host metadata

Target architecture:
- `den.hosts` is the only tracked owner of host system architecture
- one source owns host role
- `hardware/host-descriptors.nix` is reduced to script-only metadata that
  cannot be derived from evaluation, or removed entirely if no such metadata remains

Recommended implementation:
1. stop treating `hardware/host-descriptors.nix` as a second authority for
   system/role
2. derive host system from the actual declared `den.hosts` / flake configs
3. choose one owner for role:
   - either keep `custom.host.role` as the sole runtime contract signal, or
   - derive role from host composition if that becomes explicit enough
4. shrink or remove `hardware/host-descriptors.nix` accordingly
5. update onboarding generator, extension contracts, and docs

Preferred direction:
- keep a role signal only if scripts still need a simple explicit classification
- otherwise, do not keep role duplicated in both descriptors and runtime config

Files likely touched:
- `hardware/host-descriptors.nix`
- `scripts/check-dendritic-host-onboarding-contracts.sh`
- `scripts/lib/extension_contracts_checks.sh`
- `scripts/new-host-skeleton.sh`
- `docs/for-humans/03-multi-host.md`
- `docs/for-humans/workflows/103-add-host.md`

Validation:
```bash
./scripts/run-validation-gates.sh structure
bash tests/scripts/new-host-skeleton-fixture-test.sh
bash tests/scripts/dendritic-host-onboarding-contracts-fixture-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
./scripts/check-docs-drift.sh
```

Diff expectation:
- no `predator` system/HM closure change unless role sourcing changes observable
  config, which it should not

Commit target:
- `refactor: make host metadata single-source`

## Phase 5: Migrate to Den-native User Ownership

Antipatterns addressed:
- hybrid user model

Target architecture:
- host user membership is declared in `den.hosts.<system>.<name>.users`
- concrete user aspects own concrete identity
- features stop depending on `custom.user.name` where den `{ host, user }`
  context can express the same thing

Recommended implementation path:
1. declare tracked users explicitly in every host under `den.hosts...users`
2. decide tracked policy for server/example/template hosts:
   - keep `ops` as tracked safe fallback user where appropriate
   - keep `higorprado` where the repo intentionally tracks the concrete user
3. migrate `system-base` away from creating a user solely from `custom.user.name`
4. move user-creation semantics toward den batteries and user aspects
5. update private overrides so they modify host user membership/identity in the
   den-native place
6. narrow or remove `custom.user.name` after all live consumers are gone

Important constraint:
- do not break the repo's documented public/private policy during this phase
- if `ops` remains the tracked fallback, document exactly where it still exists
  and why

Files likely touched:
- `modules/features/system-base.nix`
- `modules/features/user-context.nix`
- host modules under `modules/hosts`
- user aspects under `modules/users`
- private-safety docs and workflow docs

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase5-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase5-hm
nix eval --raw path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.name
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.host.role
nix store diff-closures /tmp/antipattern-phase3-system /tmp/antipattern-phase5-system
nix store diff-closures /tmp/antipattern-phase3-hm /tmp/antipattern-phase5-hm
```

Diff expectation:
- this phase may produce real closure diffs
- every diff must be reviewed and logged, because this is a real authority shift

Commit target:
- `refactor: move tracked user ownership into den host and user contexts`

## Phase 6: Remove Repo-local Host-context Transport

Antipatterns addressed:
- duplicated host-context transport

Target architecture:
- host-dependent feature code uses den parametric contexts directly
- `host-context.nix` and HM `_module.args.host` transport disappear
- `den-host-context.nix` remains only if host schema extension is still needed

Recommended implementation path:
1. inventory all remaining `config.host.*` consumers in `.nixos`
2. inventory all remaining HM `host.*` consumers
3. migrate each host-dependent feature to den-native parametric includes or
   owned configs that receive `{ host }` or `{ host, user }`
4. once no live consumers remain:
   - delete the `host-context.nix` bridge aspect
   - remove `_module.args.host` injection from `modules/features/home-manager-settings.nix`
5. update docs to stop teaching `config.host.*` as the primary access path

Likely migration targets:
- AI package features
- desktop/browser features
- theme integration
- wallpaper/music client features
- Niri package selection

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase6-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase6-hm
nix store diff-closures /tmp/antipattern-phase5-system /tmp/antipattern-phase6-system
nix store diff-closures /tmp/antipattern-phase5-hm /tmp/antipattern-phase6-hm
rg -n "config\\.host\\.|_module\\.args\\.host|host\\.(inputs|customPkgs|llmAgentsPkgs)" modules docs -g '!reports/**'
```

Definition of done:
- no live feature logic depends on `config.host.*`
- no HM transport depends on `_module.args.host`
- remaining `host` references come from den-native parametric contexts only

Commit target:
- `refactor: use den-native host context instead of local bridge layers`

## Phase 7: Clean Desktop/Home-path Consumers and Final Docs

Antipatterns addressed:
- desktop features deriving home paths from username strings
- any remaining docs that still describe old transport/identity patterns

Target architecture:
- desktop/system features consume canonical user/home data
- no feature computes `/home/${userName}` just to recover information already
  available elsewhere

Recommended implementation:
1. rewrite DMS and desktop-service consumers to use canonical user/home data
   established in Phase 5
2. remove remaining `ConditionUser = config.custom.user.name` patterns where a
   den-native or derived canonical source is available
3. update agent docs and human docs to teach the final architecture directly
4. refresh antipattern diagnosis and priority files after the code settles

Files likely touched:
- `modules/features/dms.nix`
- desktop aspects under `modules/desktops`
- agent docs under `docs/for-agents`
- human workflow docs under `docs/for-humans`

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase7-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase7-hm
nix store diff-closures /tmp/antipattern-phase6-system /tmp/antipattern-phase7-system
nix store diff-closures /tmp/antipattern-phase6-hm /tmp/antipattern-phase7-hm
```

Commit target:
- `refactor: remove username-derived desktop path wiring`
- `docs: rewrite architecture guidance after antipattern remediation`

## Validation Matrix

Run after every meaningful slice:

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
```

Run after Nix behavior changes:

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-before
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-before

# make change

nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-after
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-after

nix store diff-closures /tmp/predator-before /tmp/predator-after
nix store diff-closures /tmp/hm-before /tmp/hm-after
```

Run when scripts/templates/docs change:

```bash
bash scripts/check-changed-files-quality.sh
bash tests/scripts/gate-cli-contracts-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
bash tests/scripts/new-host-skeleton-fixture-test.sh
```

## Risks and Failure Modes

1. **User-model migration regresses active hosts**
   - Risk: `predator` or `aurelius` lose correct user wiring
   - Mitigation: phase this separately; require closure diffs and targeted evals

2. **Host-context removal breaks HM package features**
   - Risk: HM modules lose access to `inputs` / custom packages
   - Mitigation: migrate consumers incrementally and only delete bridges last

3. **Signal removal weakens validation coverage**
   - Risk: scripts switch from synthetic booleans to poor proxies
   - Mitigation: require per-feature mapping to real config and record it in progress log

4. **Metadata dedupe breaks onboarding tooling**
   - Risk: generator/tests/docs drift from host metadata source
   - Mitigation: fixture tests must stay green before commit

5. **Public/private policy gets muddled during user-model cleanup**
   - Risk: docs and tracked config stop matching policy
   - Mitigation: rerun public-safety checks and rewrite docs in the same slice

## Commit Strategy

Recommended commits:

1. `docs: record antipattern remediation baseline`
2. `refactor: remove runtime smoke from shared validation surface`
3. `refactor: replace synthetic feature signals with real config checks`
4. `refactor: make den user-shell the sole shell owner`
5. `refactor: make host metadata single-source`
6. `refactor: move tracked user ownership into den host and user contexts`
7. `refactor: use den-native host context instead of local bridge layers`
8. `refactor: remove username-derived desktop path wiring`
9. `docs: rewrite architecture guidance after antipattern remediation`

## Success Criteria

The plan is complete when all of the following are true:

1. `custom.user.name` is no longer a second user-control plane for live feature logic
2. `config.host.*` is gone from live feature logic, or reduced to a documented compatibility shim with no new consumers
3. HM host context is no longer transported via `_module.args.host`
4. `feature-presence-signals.nix` is gone, or only retained for a narrowly documented exception
5. host system/role facts no longer exist in multiple authorities just to satisfy scripts
6. fish shell selection/enablement has one owner
7. `check-runtime-smoke.sh` is no longer part of the canonical shared gate surface
8. desktop features no longer derive home paths from username strings when canonical user/home data exists
9. docs teach the resulting architecture directly
