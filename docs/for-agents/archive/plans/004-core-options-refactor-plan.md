# Core Options Refactor Plan

Date: 2026-03-09
Owner: Codex + user
Status: planned

## Objective

Refactor `modules/features/core-options.nix`
so it stops being a multi-purpose schema dump and becomes a set of coherent,
owner-aligned modules.

This plan is intentionally about the `core-options` problem itself, not about
solving every larger architectural issue at once.

## Why This Refactor Exists

Current confirmed problems:

1. `core-options.nix` mixes unrelated concerns:
   - migration-module imports
   - `custom.user.name`
   - `custom.host.role`
   - feature-owned settings like `custom.ssh.settings`
   - feature-owned settings like `custom.fish.hostAbbreviationOverrides`
   - desktop composition parameter `custom.niri.standaloneSession`
   - validation-only feature flags like `custom.niri.enable`
   - host context mirror options `host.*`

2. Host context is modeled twice:
   - den host schema in `modules/lib/den-host-context.nix`
   - lower-level NixOS mirror in `modules/features/core-options.nix`

3. Host modules still hand-write `config.host.*` even though den already has a
   real `{ host, ... }` parametric context.

4. Repo docs and ownership rules still teach “put custom options in
   `core-options.nix`”, which reinforces the anti-pattern.

## Current Facts

These are the important current-state facts the refactor must respect.

### A. `config.host.*` still has real consumers

It is not dead. It is used by:

- `modules/features/theme.nix`
- `modules/features/niri.nix`
- `modules/features/dms-wallpaper.nix`
- `modules/features/music-client.nix`
- `modules/features/desktop-apps.nix`
- `modules/features/ai-openclaw.nix`
- `modules/features/home-manager-settings.nix` indirectly via `config.host`

Therefore the refactor must **not** delete `config.host.*` first and hope
consumers adapt later.

### B. Den already has the right upstream concept

Den provides real host context through:

- `den.hosts.<system>.<name>` metadata
- `den.schema.host`
- parametric `{ host, ... }` dispatch in aspects

That means the correct direction is:

- **derive** the NixOS bridge from den host context
- stop hand-writing the bridge in every host file

Not:

- keep manually mirroring host fields forever
- invent a third host-context model

### C. Some options are still legitimate, just in the wrong owner

These are real repo contracts/settings, not necessarily deletion targets:

- `custom.user.name`
- `custom.host.role`
- `custom.ssh.settings`
- `custom.fish.hostAbbreviationOverrides`
- `custom.niri.standaloneSession`

The problem is mainly ownership and placement.

### D. Some options are probably transitional debt

These are synthetic validation signals:

- `custom.niri.enable`
- `custom.dms.enable`
- `custom.fcitx5.enable`
- `custom.gnomeKeyring.enable`
- `custom.dmsWallpaper.enable`
- `custom.nautilus.enable`

This refactor should improve their ownership, but does **not** need to delete
them yet.

## Non-Goals

This plan does not attempt, in the same wave, to:

1. replace the full hybrid user model with pure den batteries
2. remove all validation-only `custom.<feature>.enable` flags
3. rewrite DMS home-path handling
4. change the repo to `den.default` if that is not already otherwise desired
5. redesign the entire validation architecture

Those can follow later.

## Design Principles

1. One file path should name one concern.
2. Real feature options should live with the feature that owns them.
3. Cross-cutting contracts should live in narrow contract/context modules, not
   in a feature dump.
4. `config.host.*` should remain available to existing NixOS modules, but as a
   **derived bridge**, not as per-host handwritten bookkeeping.
5. The refactor should preserve option paths where possible. Moving ownership is
   cheaper than renaming paths.
6. Docs, templates, and validation must move together with the code.

## Recommended Target Architecture

### 1. Remove `core-options.nix` as an owner

Final state:

- `core-options.nix` is deleted, or
- at most becomes a short-lived compatibility shim during migration only

It should not remain the long-term owner of unrelated schema.

### 2. Split ownership by actual concern

Recommended ownership map:

| Concern | Target owner |
|---|---|
| migration imports / removed-option compatibility | `modules/lib/option-migrations.nix` or similarly narrow compatibility module |
| den host schema extensions (`inputs`, `customPkgs`, `llmAgentsPkgs`) | `modules/lib/den-host-context.nix` |
| derived NixOS `config.host.*` bridge | new narrow host-context bridge module/aspect |
| `custom.user.name` | new narrow user-context contract module |
| `custom.host.role` | new narrow host-contract module |
| `custom.ssh.settings` | `modules/features/ssh.nix` |
| `custom.fish.hostAbbreviationOverrides` | `modules/features/fish.nix` |
| `custom.niri.standaloneSession` | `modules/features/niri.nix` or a narrow desktop/niri-options module |
| `custom.<feature>.enable` flags | the feature file that sets them |

### 3. Bridge `config.host.*` from den host context once

Recommended end state:

- host files continue declaring den-level host context in `den.hosts.<system>.<name>`
- a single parametric aspect/module derives:
  - `config.host.name = host.name`
  - `config.host.system = host.system`
  - `config.host.inputs = host.inputs`
  - `config.host.customPkgs = host.customPkgs`
  - `config.host.llmAgentsPkgs = host.llmAgentsPkgs`
- host files stop hand-writing those assignments

This is the most important architectural move in the plan.

## Execution Plan

### Phase 0: Baseline and Guardrails

Purpose:
- capture current behavior before any ownership moves
- add temporary guardrails so the migration cannot silently regress

Actions:
- create a dedicated progress log before starting execution
- baseline:
  - `nix build .#nixosConfigurations.predator.config.system.build.toplevel`
  - `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
  - `nix store diff-closures` before/after per behavior-affecting slice
- capture current `core-options` consumers with repo-wide searches
- add temporary grep-based checks during the migration if needed

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- before/after closure diffs for any Nix-behavior change

Definition of done:
- baseline commands and consumer inventory are recorded in the progress log

### Phase 1: Extract Migration Plumbing Out of `core-options`

Purpose:
- separate compatibility machinery from live schema ownership

Actions:
- create a narrow module for:
  - alias imports from `_migration-registry.nix`
  - removed-option imports from `_migration-registry.nix`
- remove that responsibility from `core-options.nix`

Recommended target:
- `modules/lib/option-migrations.nix`

Notes:
- this phase should not change any option path
- it is a pure ownership cleanup

Validation:
- `./scripts/check-option-migrations.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Definition of done:
- `core-options.nix` no longer owns migration import wiring

### Phase 2: Introduce a Derived Host-Context Bridge

Purpose:
- stop hand-writing `config.host.*` in every host file
- make den the authority again

Actions:
- create a narrow aspect/module, for example:
  - `modules/features/host-context-bridge.nix`
  - or `modules/lib/host-context-bridge.nix` if you want it clearly non-feature
- implement it as a den parametric host-context bridge derived from `{ host, ... }`
- map den host metadata into `config.host.*`
- update hosts to stop assigning:
  - `host.name`
  - `host.system`
  - `host.inputs`
  - `host.customPkgs`
  - `host.llmAgentsPkgs`

Important constraint:
- keep `config.host.*` available to existing NixOS consumers
- do **not** rewrite all consumers in this phase

Expected result:
- host modules declare only den host metadata under `den.hosts...`
- one bridge provides `config.host.*` everywhere it is needed

Validation:
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix store diff-closures` for both outputs
- `./scripts/run-validation-gates.sh structure`
- repo-wide check that host modules no longer assign `host.inputs`, `host.customPkgs`, etc.

Definition of done:
- no host file manually writes `config.host.*`
- `config.host.*` still works for existing consumers

### Phase 3: Split Cross-Cutting Contract Options

Purpose:
- remove unrelated cross-cutting contracts from the dump file

Actions:
- move `custom.user.name` declaration into a narrow user-context contract module
- move `custom.host.role` declaration into a narrow host-contract module

Recommended targets:
- `modules/features/user-context.nix`
- `modules/features/host-contracts.nix`

Rationale:
- these are real repo-wide contracts, but not “core options” in the generic
  sense

Notes:
- keep option paths unchanged
- this phase is about ownership, not semantic redesign

Validation:
- `./scripts/check-config-contracts.sh`
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix eval` checks for `custom.user.name` and `custom.host.role` on real hosts

Definition of done:
- `core-options.nix` no longer declares `custom.user.name` or `custom.host.role`

### Phase 4: Move Feature Options to Their Feature Owners

Purpose:
- make each feature own the options it reads or sets

Actions:
- move `custom.ssh.settings` declaration into `modules/features/ssh.nix`
- move `custom.fish.hostAbbreviationOverrides` declaration into `modules/features/fish.nix`
- move `custom.niri.standaloneSession` declaration into `modules/features/niri.nix` or a narrow desktop/niri option module if that reads cleaner
- move declarations of:
  - `custom.niri.enable`
  - `custom.dms.enable`
  - `custom.fcitx5.enable`
  - `custom.gnomeKeyring.enable`
  - `custom.dmsWallpaper.enable`
  - `custom.nautilus.enable`
  into the same feature file that sets each flag

Rationale:
- even if synthetic flags remain for now, declaration and setter should live in
  the same owner

Risk:
- if a host sets a feature-specific option without including that feature, the
  move will expose the bug immediately

Pre-move check:
- verify each option setter is only present on hosts that include the owning
  feature

Validation:
- `./scripts/check-config-contracts.sh`
- `./scripts/run-validation-gates.sh predator`
- `./scripts/run-validation-gates.sh server-example`
- `./scripts/run-validation-gates.sh aurelius`
- closure diffs for `predator`

Definition of done:
- feature-specific options are declared by their feature owners

### Phase 5: Turn `core-options.nix` Into a Thin Shim, Then Delete It

Purpose:
- complete the refactor instead of stopping at half-split ownership

Actions:
- once Phases 1-4 are green, reduce `core-options.nix` to:
  - temporary imports only, or
  - nothing
- update host includes to stop referencing `core-options`
- update templates and docs to stop teaching `core-options`
- then delete the file when all hosts and docs are migrated

Decision rule:
- if removing it immediately would create churn, keep it one short transitional
  commit as a shim
- but the final state of this plan should be: no architectural dependency on
  `core-options`

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`
- repo-wide `rg -n "core-options" modules docs tests templates`

Definition of done:
- host includes and docs no longer rely on `core-options`
- the file is removed or reduced to a temporary shim with a clear deletion
  follow-up

### Phase 6: Rewrite Docs and Ownership Rules

Purpose:
- make the repo self-describe the new architecture truthfully

Files that will need updates:
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- `docs/for-humans/workflows/102-add-feature.md`
- `docs/for-humans/workflows/103-add-host.md`

Required doc changes:
- stop teaching “declare options in core-options.nix”
- document the host-context bridge as derived from den
- document narrow contract modules for `custom.user.name` and `custom.host.role`
- document feature ownership for feature options

Validation:
- `./scripts/check-docs-drift.sh`
- any fixture tests tied to generated host/module docs

Definition of done:
- the docs teach the new architecture directly

## Validation Matrix

Run after each meaningful slice:

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
```

Run after any Nix behavior change:

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-before
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-before

# make change

nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-after
nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-after

nix store diff-closures /tmp/predator-before /tmp/predator-after
nix store diff-closures /tmp/hm-before /tmp/hm-after
```

Run when script/docs/template files change:

```bash
bash scripts/check-changed-files-quality.sh
bash tests/scripts/gate-cli-contracts-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
bash tests/scripts/new-host-skeleton-fixture-test.sh
```

Targeted validations by phase:

- host bridge phase:
  - `./scripts/run-validation-gates.sh predator`
  - `./scripts/run-validation-gates.sh aurelius`
- feature-option split phase:
  - `./scripts/check-config-contracts.sh`
- final cleanup:
  - repo-wide search confirming `core-options` references are gone or only
    historical

## Risks and Failure Modes

1. **Host bridge recursion or wrong context source**
   - Risk: implementing the bridge in the wrong context layer
   - Mitigation: build it from den parametric `{ host, ... }` context, not from
     recursive NixOS imports

2. **Option declaration moves exposing orphan setters**
   - Risk: a host sets `custom.ssh.settings` without including `ssh`
   - Mitigation: audit setters before moving declarations

3. **Docs lagging behind architecture**
   - Risk: repo remains inconsistent after code cleanup
   - Mitigation: treat docs rewrite as a required final phase, not optional

4. **Stopping at a compatibility shim**
   - Risk: `core-options.nix` survives as a renamed dumping ground
   - Mitigation: define deletion as part of completion criteria

## Suggested Commit Strategy

Recommended commit sequence:

1. `refactor: extract option migration wiring from core-options`
2. `refactor: derive config.host bridge from den host context`
3. `refactor: split user and host contract options`
4. `refactor: move feature options to owning modules`
5. `refactor: retire core-options shim`
6. `docs: update ownership and extensibility guidance after core-options split`

Each commit should end with:
- validation
- diff review
- progress log update

## Success Criteria

This refactor is complete when:

1. `core-options.nix` no longer owns unrelated option declarations
2. migration wiring is isolated from live schema ownership
3. `config.host.*` is derived from den host context, not handwritten per host
4. `custom.user.name` and `custom.host.role` live in narrow contract modules
5. feature-owned options are declared by the feature that reads/sets them
6. hosts, templates, and docs no longer teach `core-options` as the central
   place for all options
7. all required validations pass with acceptable closure diffs

## Recommended First Implementation Order

1. Phase 1: migration plumbing
2. Phase 2: host bridge
3. Phase 3: user/host contract split
4. Phase 4: feature-owned option moves
5. Phase 5: remove shim
6. Phase 6: docs rewrite

This order keeps the biggest architectural risk first where it matters
(`config.host` authority), but still avoids mixing it with the broader user-model
rewrite or validation-flag removal.
