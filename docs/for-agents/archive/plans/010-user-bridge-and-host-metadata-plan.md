# User Bridge and Host Metadata Plan

Date: 2026-03-10
Status: planned

Source diagnosis:
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/004-antipattern-priority-order.md`

Execution log:
- `docs/for-agents/current/012-user-bridge-and-host-metadata-progress.md`

## Goal

Fix the three remaining non-intentional architectural issues:

1. the hybrid user model around `custom.user.name`
2. the remaining host metadata duplication / multi-authority shape
3. the ambiguous status of `check-runtime-smoke.sh`

The plan must preserve current behavior while reducing synthetic ownership.

## Scope

In scope:
- tracked consumers of `config.custom.user.name`
- the bridge itself in `modules/features/user-context.nix`
- host metadata ownership across:
  - `modules/hosts`
  - `hardware`
  - `hardware/host-descriptors.nix`
  - validation scripts that enforce host metadata contracts
- runtime smoke boundary / usefulness
- docs, tests, and validation scripts affected by these changes

Out of scope:
- pinning fast-moving personal packages
- broad CI redesign
- splitting `fish.nix` or `theme.nix` for LOC alone
- removing `custom.host.role` at any cost if it would replace one explicit contract with heuristics
- redesigning private override architecture beyond what is necessary to narrow the bridge cleanly

## Current State

### `custom.user.name` live tracked consumers

Bridge owner:
- `modules/features/user-context.nix`

Tracked feature/hardware consumers:
- `modules/features/system-base.nix`
- `modules/features/docker.nix`
- `modules/features/bluetooth.nix`
- `modules/features/keyrs.nix`
- `hardware/predator/hardware/laptop-acer.nix`
- `modules/features/nix-settings.nix`
- `modules/features/niri.nix`
- `modules/features/dms.nix`

Private/example/docs consumers:
- `hardware/aurelius/private.nix.example`
- `docs/for-humans/04-private-overrides.md`
- `docs/for-humans/workflows/105-private-overrides.md`

Validation consumers:
- `scripts/check-config-contracts.sh`
- `scripts/run-validation-gates.sh`

### Host metadata authorities today

Current facts and owners:
- host membership: `den.hosts.<system>.<host>` in host modules
- host system: host module path + local `system = "..."`
- host name: host attr name plus `networking.hostName = "..."`
- host integrations: `hardware/host-descriptors.nix`
- host runtime role: `hardware` via `custom.host.role`

Important distinction:
- `hardware/host-descriptors.nix` is already script-only metadata
- the real duplication problem is not the descriptors file itself
- the real problem is where the same host fact still has more than one live authority

### Runtime smoke today

- `scripts/check-runtime-smoke.sh` is documented as predator-only
- it is not part of `scripts/run-validation-gates.sh`
- it still lives in tracked shared `scripts/`
- it checks real runtime/session behavior that eval/build cannot cover

## Relevant Upstream Patterns

From `den`:
- `den.ctx.host` creates one `{ host }` context per host
- `den.ctx.host.into.user` creates one `{ host, user }` context per declared host user
- `den._.define-user` owns OS/HM account identity
- `den._.primary-user` owns admin groups
- `den._.user-shell` owns login shell + HM shell enablement
- `den._.hostname` can own `networking.hostName`

Relevant upstream references:
- ~/git/den/docs/src/content/docs/reference/ctx.mdx
- ~/git/den/docs/src/content/docs/reference/batteries.mdx
- ~/git/den/modules/aspects/provides/define-user.nix
- ~/git/den/modules/aspects/provides/primary-user.nix
- ~/git/den/modules/aspects/provides/hostname.nix

From `dendritic`:
- every file should own one feature/concern
- avoid ad-hoc pass-through transport layers when the top-level/module context already carries the needed data
- avoid multi-authority metadata when one owner can be evaluated directly

## Target Architecture

### User identity

1. Tracked user identity should come from `den.hosts` plus user aspects/batteries.
2. User-scoped feature changes should use `{ host, user }` context or user aspects, not `config.custom.user.name`.
3. Host-scoped features that truly need one chosen interactive user should derive that from declared host users through one helper, not via a broad bridge reused everywhere.

### Compatibility bridge

`custom.user.name` should stop being a general-purpose feature dependency.

Near-term target:
- tracked feature/hardware consumers: `0`
- tracked validation consumers: only those intentionally validating the bridge while it still exists
- remaining live owner: `modules/features/user-context.nix`
- allowed remaining use: private override surface and any temporary validation/docs tied to that compatibility promise

### Host metadata

1. `hardware/host-descriptors.nix` remains only for script-only integrations metadata.
2. `networking.hostName` should be den-owned via `den._.hostname`.
3. `custom.host.role` stays only if it remains the single explicit runtime contract signal.
4. Do not replace explicit role with brittle heuristics unless the replacement is clearly better.

### Runtime smoke

The repo should end with one explicit answer:
- either runtime smoke is a real tracked auxiliary tool
- or it is private host-local ops and leaves the repo

No ambiguous “shared but not really shared” state.

## Migration Classification

### Can migrate off `custom.user.name` now

These are mechanically replaceable with den-native user context.

1. `modules/features/system-base.nix`
   - current use: base extra groups for one user
   - target: user-scoped contribution through `{ host, user }`

2. `modules/features/docker.nix`
   - current use: add `docker` group to one user
   - target: user-scoped contribution through `{ host, user }`

3. `modules/features/bluetooth.nix`
   - current use: add `rfkill` group to one user
   - target: user-scoped contribution through `{ host, user }`

4. `modules/features/keyrs.nix`
   - current use: add `uinput` group to one user
   - target: user-scoped contribution through `{ host, user }`

5. `hardware/predator/hardware/laptop-acer.nix`
   - current use: add `linuwu_sense` group to one user
   - target: user-scoped contribution through a den-aware hardware-facing helper/aspect boundary

6. `modules/features/nix-settings.nix`
   - current use: add one username to `nix.settings.trusted-users`
   - target: derive from declared tracked users instead of one bridge username

### Can migrate after a small “primary tracked user” helper exists

These are host-scoped settings that need one concrete user, not a list.

1. `modules/features/niri.nix`
   - current use: `services.greetd.settings.default_session.user`
   - constraint: host-scoped setting needs exactly one chosen login user

2. `modules/features/dms.nix`
   - current use: derive greeter `configHome` from the selected user’s home
   - constraint: host-scoped setting needs the chosen login user’s home

Recommended mechanism:
- a small helper in `lib` that derives the sole tracked host user from `{ host }`
- used only by host-scoped features that truly need one selected user
- not exposed as a new broad `config.custom.*` compatibility API

### Should keep `custom.user.name` for now

These are the cases where removing the bridge immediately would either break the current private-override contract or require a broader redesign.

1. `modules/features/user-context.nix`
   - remains as the bridge owner until private-override/user-selection strategy is intentionally changed

2. Private override surface
   - `hardware/aurelius/private.nix.example`
   - `docs/for-humans/04-private-overrides.md`
   - `docs/for-humans/workflows/105-private-overrides.md`

Reason:
- private `hardware/*/private.nix` files are lower-level NixOS modules
- they cannot directly rewrite `den.hosts.<system>.<host>.users`
- today they still rely on a config-level compatibility selector

3. Validation scripts that explicitly test the bridge while it exists
   - `scripts/check-config-contracts.sh`
   - `scripts/run-validation-gates.sh`

## Phases

## Phase 0: Baseline and Authority Table

Purpose:
- capture pre-change behavior
- record which metadata remains explicit by design versus which is true duplication

Changes:
- create/update progress log
- record baseline eval outputs and closures
- add an authority table in the progress log

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/user-bridge-before-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/user-bridge-before-hm
nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name
nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.host.role
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.host.role
```

Commit target:
- none unless a doc-only baseline table is added as a focused planning commit

## Phase 1: Remove the Easy User-Bridge Consumers

Goal:
- remove `custom.user.name` from consumers that are purely user-scoped

Files:
- `modules/features/system-base.nix`
- `modules/features/docker.nix`
- `modules/features/bluetooth.nix`
- `modules/features/keyrs.nix`
- `hardware/predator/hardware/laptop-acer.nix`

Recommended implementation:
1. move group ownership into `{ host, user }`-scoped contributions
2. stop creating these groups through a single username string
3. keep behavior identical for the current one-user hosts

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/user-bridge-phase1-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/user-bridge-phase1-hm
nix store diff-closures /tmp/user-bridge-before-system /tmp/user-bridge-phase1-system
nix store diff-closures /tmp/user-bridge-before-hm /tmp/user-bridge-phase1-hm
```

Diff expectation:
- empty or only ownership-path-neutral diffs

Commit target:
- `refactor: move user-scoped group ownership to den user context`

## Phase 2: Remove the Derived-List User Consumer

Goal:
- remove `custom.user.name` from `nix-settings`

File:
- `modules/features/nix-settings.nix`

Recommended implementation:
1. derive trusted users from declared tracked users
2. keep `root`
3. do not require one special username string

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix eval --json path:$PWD#nixosConfigurations.predator.config.nix.settings.trusted-users
nix eval --json path:$PWD#nixosConfigurations.aurelius.config.nix.settings.trusted-users
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/user-bridge-phase2-system
nix store diff-closures /tmp/user-bridge-phase1-system /tmp/user-bridge-phase2-system
```

Diff expectation:
- empty

Commit target:
- `refactor: derive trusted users from tracked host users`

## Phase 3: Introduce a Narrow “Primary Tracked User” Helper

Goal:
- replace broad bridge usage for host-scoped login-user settings with one narrow helper

Reason:
- `niri` and `dms` need one selected interactive user at host scope
- using full `custom.user.name` everywhere is too broad
- removing all user selection logic without replacement would be wrong

Recommended implementation:
1. add one helper under `lib` that:
   - takes `{ host }`
   - asserts exactly one tracked host user
   - returns that user record / userName
2. use it only where a host-scoped feature truly needs one user
3. do not create a new `options.custom.*` compatibility layer

Validation:
```bash
./scripts/run-validation-gates.sh structure
bash scripts/check-changed-files-quality.sh
```

Commit target:
- `refactor: add primary tracked user helper`

## Phase 4: Remove the Remaining Tracked Feature Uses of `custom.user.name`

Goal:
- migrate host-scoped single-user consumers to the new helper

Files:
- `modules/features/niri.nix`
- `modules/features/dms.nix`

Recommended implementation:
1. derive greetd default session user from the helper, not the bridge
2. derive DMS greeter home/config path from the helper, not the bridge
3. keep current behavior for one-user hosts unchanged

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/user-bridge-phase4-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/user-bridge-phase4-hm
nix store diff-closures /tmp/user-bridge-phase2-system /tmp/user-bridge-phase4-system
nix store diff-closures /tmp/user-bridge-phase1-hm /tmp/user-bridge-phase4-hm
```

Diff expectation:
- empty

Commit target:
- `refactor: remove tracked feature dependence on custom.user.name`

## Phase 5: Narrow the Bridge Contract Instead of Deleting It

Goal:
- keep `custom.user.name` only where the current private override story still needs it

Files:
- `modules/features/user-context.nix`
- `scripts/check-config-contracts.sh`
- `scripts/run-validation-gates.sh`
- `docs/for-humans/04-private-overrides.md`
- `docs/for-humans/workflows/105-private-overrides.md`
- `hardware/aurelius/private.nix.example`

Recommended implementation:
1. reword the bridge as compatibility-only
2. stop claiming feature modules should use it dynamically once tracked consumers are gone
3. keep validation only for the compatibility contract that still remains

Success target:
- tracked feature/hardware consumers of `custom.user.name`: `0`
- tracked compatibility bridge owners: `<= 4` files plus docs/examples

Validation:
```bash
./scripts/check-config-contracts.sh
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
```

Commit target:
- `docs+contracts: narrow custom.user.name to compatibility scope`

## Phase 6: Deduplicate the Easy Host Metadata First

Goal:
- remove host-name duplication safely

Files:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `hardware/predator/default.nix`
- `hardware/aurelius/default.nix`
- docs referencing hostName ownership

Recommended implementation:
1. adopt `den._.hostname`
2. set `hostName` in `den.hosts` only where non-default is needed, otherwise rely on default attr-name behavior
3. remove manual `networking.hostName = "..."`

Validation:
```bash
./scripts/run-validation-gates.sh structure
nix eval --raw path:$PWD#nixosConfigurations.predator.config.networking.hostName
nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.networking.hostName
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/host-metadata-phase6-system
nix store diff-closures /tmp/user-bridge-phase4-system /tmp/host-metadata-phase6-system
```

Diff expectation:
- empty

Commit target:
- `refactor: make den hostname the sole hostname owner`

## Phase 7: Clarify the Role and Descriptor Boundary

Goal:
- stop treating script-only metadata as if it were runtime duplication
- decide whether `custom.host.role` remains the explicit runtime signal

Recommended decision order:
1. keep `hardware/host-descriptors.nix` only for `integrations`
2. keep `custom.host.role` only if validation/runtime tooling still benefits from an explicit runtime signal
3. if `custom.host.role` stays, update docs to say it is a deliberate contract, not “duplication waiting to die”
4. only remove `custom.host.role` if there is a clear non-heuristic replacement authority

Expected likely outcome:
- descriptors stay
- `custom.host.role` stays for now
- the repo stops misclassifying that split as accidental duplication

Validation:
```bash
./scripts/check-extension-contracts.sh
./scripts/check-config-contracts.sh
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
```

Commit target:
- `docs+contracts: clarify host metadata ownership`

## Phase 8: Decide the Runtime Smoke Boundary

Goal:
- make `check-runtime-smoke.sh` either clearly shared or clearly local

Decision criteria:
1. keep it tracked only if it is actually part of the real post-switch local workflow
2. if kept, either:
   - rename it to make predator scope explicit, or
   - parameterize it enough to stop being a one-host special case
3. if not kept, move it to `~/ops/nixos-private-scripts/bin` and remove tracked references

Recommended default:
- keep it only if you really use it after desktop switches
- otherwise demote it out of the repo

Low-churn improvement path if retained:
1. rename or reclassify it as explicitly predator-local
2. reduce duplicated feature detection by reusing the same real-config probes already used in `scripts/check-config-contracts.sh`

Validation:
```bash
bash tests/scripts/gate-cli-contracts-test.sh
./scripts/check-docs-drift.sh
bash scripts/check-changed-files-quality.sh
```

Commit target:
- `refactor: clarify runtime smoke ownership`

## Testing Discipline

After each meaningful slice:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
```

When system or HM behavior may change:
```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/<phase>-system
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/<phase>-hm
nix store diff-closures /tmp/<before>-system /tmp/<phase>-system
nix store diff-closures /tmp/<before>-hm /tmp/<phase>-hm
```

For host-sensitive phases:
```bash
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
```

## Commit Strategy

One focused commit per phase or sub-phase. Recommended sequence:

1. `refactor: move user-scoped group ownership to den user context`
2. `refactor: derive trusted users from tracked host users`
3. `refactor: add primary tracked user helper`
4. `refactor: remove tracked feature dependence on custom.user.name`
5. `docs+contracts: narrow custom.user.name to compatibility scope`
6. `refactor: make den hostname the sole hostname owner`
7. `docs+contracts: clarify host metadata ownership`
8. `refactor: clarify runtime smoke ownership`

## Success Criteria

Mandatory:
- tracked feature/hardware consumers of `config.custom.user.name`: `0`
- `custom.user.name` remains only as a compatibility bridge, not as a general feature API
- `networking.hostName` manual assignments in host hardware defaults: `0`
- host descriptors remain script-only integrations metadata
- docs and validation contracts describe the new authority boundaries correctly

Nice to have:
- runtime smoke either moved out of the repo or made obviously predator-local
- `custom.host.role` reclassified as a deliberate contract if retained

## Main Risks

1. Accidentally changing user/group ownership semantics while migrating off the bridge.
2. Breaking greetd or DMS by replacing one selected user with an unordered host user lookup.
3. Removing explicit host-role signaling without a trustworthy replacement.
4. Mixing “compatibility bridge removal” with “private override redesign” in one unsafe slice.

## Recommended Order

1. Phase 0 baseline
2. Phase 1 easy user-scoped consumers
3. Phase 2 trusted-users
4. Phase 3 helper
5. Phase 4 host-scoped single-user consumers
6. Phase 5 narrow bridge/docs/contracts
7. Phase 6 hostname dedup
8. Phase 7 metadata clarification
9. Phase 8 runtime smoke decision
