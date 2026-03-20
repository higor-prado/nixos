# Runtime Simplification Plan

## Objective

Bring the runtime closer to the actual dendritic pattern used in
`~/git/dendritic`, not just to a den-free runtime that happens to work.

This plan is about removing artificial structure.

The core standard is:

1. every non-entry-point file stays a top-level module,
2. lower-level modules live under `flake.modules.*`,
3. concrete compositions live under `configurations.*.<name>.module`,
4. top-level options exist only when they represent:
   - structural composition, or
   - narrow shared facts with real semantic meaning.

Anything else is suspect.

## Reference Reading

This plan is based on the actual example modules in `~/git/dendritic`:

- `example/modules/flake-parts.nix`
- `example/modules/systems.nix`
- `example/modules/nixos.nix`
- `example/modules/meta.nix`
- `example/modules/shell.nix`
- `example/modules/admin.nix`
- `example/modules/desktop.nix`

## What The Reference Actually Does

The important part is not "use `flake.modules`".

The important part is **what kinds of options exist**.

### 1. Structural options

These define how lower-level configurations are declared and emitted.

Example:

- `configurations.nixos.<name>.module`

This is a valid use of `mkOption` because it defines the top-level structure of
the repo.

### 2. Narrow semantic facts

These are shared facts that multiple top-level modules legitimately need.

Examples from the reference:

- `username`

That option is narrow, meaningful, and directly consumed by lower-level module
publishers such as `shell.nix` and `admin.nix`.

### 3. Concrete composition

The concrete host/config module imports published lower-level modules by name.

Example:

```nix
let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.desktop.module = {
    imports = [
      nixos.admin
      nixos.shell
    ];
  };
}
```

The reference does **not** create:

- a generic runtime carrier,
- an inventory bag that doubles as transport,
- a compatibility bridge that survives after the migration,
- a schema full of fields that are not actually read by other modules.

## Core Diagnosis

Our current runtime still has several non-dendritic leftovers.

### A. Artificial carrier

This is the biggest problem.

Current bad shape:

- `repo.context`
- `mkRepoContextOptions`
- `generic.repo-context`
- `contextModule`

This is not a dendritic shared fact. It is a transport object.

### B. Overmodeled user inventory

`repo.users.*` currently carries much more schema than the runtime actually
uses.

Today the tracked code only really consumes the username from that surface in
host composition. The rest is duplicated in `modules/users/higorprado.nix` and
not meaningfully consumed through inventory.

That means `repo.users.*` is currently closer to a local database than to a
necessary top-level shared fact.

### C. Runtime payload disguised as inventory

`repo.hosts.*.llmAgents` does not describe the host. It transports package
selection.

That is not inventory. It is host-local runtime payload.

### D. Compatibility surfaces that may have outlived their purpose

`custom.user.name` still exists as a bridge.

If no tracked runtime code truly needs it anymore, it should be deleted rather
than defended.

### E. Test-only anti-patterns

Some test harnesses still use shapes that the runtime itself is trying to avoid,
especially:

- `specialArgs` in `scripts/check-desktop-composition-matrix.sh`
- synthetic option declarations there just to evaluate compositions

If a test only exists by recreating the anti-pattern, it should be rewritten.

## Option Triage

This is the standard for every `mkOption` in the repo.

### Clearly justified

These match the dendritic reference:

- `modules/options/configurations-nixos.nix`
  - structural composition option
- `modules/options/flake-parts-modules.nix`
  - not even an option layer, just official flake-parts integration
- `modules/features/desktop/niri.nix`
  - `custom.niri.standaloneSession`
  - narrow feature-owned semantic input
- `modules/options/inventory.nix`
  - only for the fields that truly represent shared top-level facts

### Suspect and likely removable or reducible

- `modules/options/repo-runtime-contracts.nix`
  - especially `repo.context`
  - likely also `custom.user.name`
- `modules/options/inventory.nix`
  - user fields that are not actually shared through top-level config
  - host fields that are really runtime payload instead of inventory

## Desired End State

### Keep

- `flake.modules.*`
- `configurations.nixos.*.module`
- `repo.hosts.*` only as actual host inventory
- a minimal user-sharing surface only if it is truly justified
- narrow feature-owned options only where the feature really owns a semantic
  input

### Remove

- `repo.context`
- `mkRepoContextOptions`
- `generic.repo-context`
- `contextModule`
- `repo.hosts.*.llmAgents`
- any repo-wide bag whose job is to transport host/user/runtime values
- any inventory field that is not meaningfully consumed as shared top-level
  state

## Correct Replacement Model

This is the part that needs to be explicit.

### 1. Do not replace one carrier with another

Banned replacements:

- `config.host`
- `_module.args.host`
- `_module.args.repoContext`
- `repo.runtime`
- `repo.selection`
- any other bag of host/user/runtime payload

### 2. Use existing lower-level state first

Before creating any option, try the lower-level state that already exists.

Examples:

- HM username:
  - `config.home.username`
- NixOS hostname:
  - `config.networking.hostName`
- HM nested inside NixOS:
  - `osConfig`

### 3. If a value is host-local and shallow, keep it in host composition

Do not create options for host-local package choices that are only used once.

Examples:

- `llm-agents` packages
- `music-client` package additions
- `desktop-apps` extra browser package selection

These should be host-owned materialization, not top-level schema.

### 4. If a feature owns the meaning, the feature may own a narrow option

Examples:

- `custom.niri.package`
- `custom.niri.xwaylandSatellitePackage`
- `custom.niri.sessionUser`
- `custom.dms.homeModule`
- `custom.themeZen.package`

The rule is: one feature, one meaning, one narrow option surface if needed.

## Module-by-Module Direction

### `modules/options/repo-runtime-contracts.nix`

Current problem:

- contains the runtime carrier
- may also contain a stale compatibility bridge

Plan:

- delete `repo.context`
- re-evaluate `custom.user.name`
- keep `custom.host.role` only if validation/tooling still genuinely needs it

### `modules/options/inventory.nix`

Current problem:

- user schema is richer than actual shared usage
- host schema still contains runtime payload (`llmAgents`)

Plan:

- remove `llmAgents`
- reduce `repo.users.*` to what is actually shared through top-level config
- if only `userName` is really shared, say so in code and docs
- if other fields are only local to `modules/users/higorprado.nix`, keep them
  local there instead of schema-ifying them

### `modules/features/core/nix-settings.nix`

Current problem:

- reads `config.repo.context.host.trackedUsers`

Correct replacement:

- `config.repo.hosts.${config.networking.hostName}.trackedUsers`

No new option.

### `modules/features/dev/llm-agents.nix`

Current problem:

- reads host-local package payload through the carrier

Correct replacement:

- stop publishing this as a host-context consumer
- move package materialization into host composition

This feature probably becomes smaller or disappears as a publisher.

### `modules/features/desktop/desktop-apps.nix`

Current problem:

- host-specific package selection is hidden behind the carrier

Correct replacement:

- keep shared browser/mime logic in the feature
- move host-local package selection into the host unless reuse proves otherwise

### `modules/features/desktop/music-client.nix`

Current problem:

- host-specific package payload passed through the carrier

Correct replacement:

- keep generic service/config logic in the feature
- host injects extra packages directly

### `modules/features/desktop/theme-zen.nix`

Current problem:

- reads one package from the carrier

Correct replacement:

- one narrow feature-owned option if needed

This is justified because the package is central to the feature itself.

### `modules/features/desktop/niri.nix`

Current problem:

- reads runtime package/session data from the carrier

Correct replacement:

- keep `custom.niri.standaloneSession`
- add only the exact feature-owned inputs needed by Niri

### `modules/features/desktop/dms.nix`

Current problem:

- carrier used both for DMS module input and selected username

Correct replacement:

- HM module reference becomes a narrow DMS-owned input if needed
- selected username should come from the correct lower-level source where
  possible, otherwise one narrow DMS-owned input

### `modules/features/desktop/dms-wallpaper.nix`

Current problem:

- carrier used for package/module transport

Correct replacement:

- use narrow DMS-wallpaper-owned inputs if the feature really owns them
- otherwise host-local materialization

### `modules/hosts/predator.nix` and `modules/hosts/aurelius.nix`

Current problems:

- verbose `config.flake.modules.*` consumption
- `contextModule` / `generic.repo-context`
- dependence on `repo.users.*` for data that may not need to be top-level

Correct replacement:

- use local aliases:
  - `inherit (config.flake.modules) nixos homeManager;`
- remove carrier wiring entirely
- keep only explicit composition and genuinely host-owned materialization

## Tests And Scripts To Rework

### Must stop depending on `repo.context`

- `scripts/run-validation-gates.sh`
- `scripts/check-config-contracts.sh`
- `scripts/lib/extension_contracts_eval.sh`
- `tests/scripts/run-validation-gates-fixture-test.sh`

### Must stop teaching the wrong runtime shape

- `scripts/check-bare-host-in-includes.sh`
- docs under `docs/for-agents/` and `docs/for-humans/`
- host skeleton templates and fixtures

### Must be re-evaluated for anti-pattern test scaffolding

- `scripts/check-desktop-composition-matrix.sh`

Current issue:

- uses `specialArgs`
- declares synthetic options in the harness

Plan:

- keep it only if we can express the simulation without teaching the repo the
  wrong shape
- otherwise rewrite or drop it

## Phases

### Phase 0: Kill the bad in-flight slice

Discard the uncommitted experiment that introduced:

- `generic.repo-context`
- `contextModule`
- docs/templates that teach that shape

Keep only:

- the rewritten plan
- a progress log that records that the slice was rejected

### Phase 1: Cheap readability cleanup

Do only:

- local `inherit (config.flake.modules) nixos homeManager;`

No runtime semantics yet.

### Phase 2: Kill the carrier in simple consumers

Targets:

- `nix-settings`
- script/gate consumers of `repo.context.userName`
- tracked-user reads

### Phase 3: Remove fake inventory payload

Targets:

- `repo.hosts.*.llmAgents`
- any other runtime payload living under inventory

### Phase 4: Reduce or delete overmodeled user inventory

Targets:

- `repo.users.*`

Question to answer in code, not theory:

- which fields are actually shared top-level facts?
- which fields are just local constants from `modules/users/higorprado.nix`?

Delete the second category from inventory.

### Phase 5: Replace host payload consumers the right way

Split by correct replacement:

- host-local materialization:
  - `llm-agents`
  - `music-client`
  - likely part of `desktop-apps`
- narrow feature-owned options:
  - `niri`
  - `dms`
  - `dms-wallpaper`
  - `theme-zen`

### Phase 6: Delete carrier infrastructure

Delete:

- `repo.context`
- `mkRepoContextOptions`
- `generic.repo-context`
- `contextModule`

### Phase 7: Rewrite docs and tests to the final shape

After the runtime is clean:

- rewrite agent docs
- rewrite human docs
- rewrite skeleton templates
- rewrite fixtures
- rewrite or drop anti-pattern test harnesses

## Success Criteria

The runtime is only considered clean when all of this is true:

1. no tracked runtime code uses `repo.context`
2. no tracked runtime code defines `mkRepoContextOptions`
3. no tracked runtime code publishes/imports `generic.repo-context`
4. host files consume `flake.modules` via local aliases
5. `repo.hosts.*` contains host inventory, not runtime payload
6. `repo.users.*` contains only real shared top-level user facts, or is reduced
   away if not justified
7. only narrow semantic options remain
8. tests and docs stop teaching the anti-patterns

## Anti-Regression Rules

Reject any change that:

- introduces a new generic runtime bag
- adds schema for values that are not meaningfully consumed as shared top-level
  state
- uses `mkOption` as transport infrastructure
- keeps compatibility bridges after tracked runtime code has stopped needing them
- recreates `specialArgs` indirectly under another name
