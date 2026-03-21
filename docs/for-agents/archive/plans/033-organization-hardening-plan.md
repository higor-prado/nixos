# Organization Hardening Plan

## Goal

Improve the current repo organization where it has become too broad,
duplicated, or conceptually blurry after the Den removal, while preserving the
current strengths: explicit host composition, repo-local runtime ownership, and
low framework magic. The target is not a redesign. The target is to remove real
maintenance drag without reintroducing indirection.

## Scope

In scope:
- tighten user-vs-host ownership where the current user owner is too broad
- reduce baseline duplication across concrete host modules where it creates real
  drift risk
- separate true tracked inventory from runtime baggage where the current model
  is too mixed
- reduce duplicate control planes where they are still transitional
- update living docs to describe the cleaned-up shape

Out of scope:
- introducing a new repo-local framework
- rebuilding Den-like batteries or implicit include systems
- abstracting host composition behind generators or hidden helpers
- changing private override policy beyond what is needed for ownership cleanup
- speculative schema design for future hosts/users that do not exist yet

## Current State

- Host composition is now explicit and repo-local in:
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
- The canonical runtime surfaces are now repo-owned in:
  - `modules/options/configurations-nixos.nix`
  - `modules/options/inventory.nix`
  - `modules/options/repo-runtime-contracts.nix`
- The current organization is clearer than the old Den-based shape, but it has
  accumulated a few weaknesses:
  - `modules/users/higorprado.nix` now owns groups that are likely not truly
    universal across all hosts
  - baseline imports are repeated across host modules
  - `repo.hosts.*` currently mixes tracked inventory facts with runtime-heavy
    values such as `inputs`, `customPkgs`, `hardwareImports`, and package lists
  - `custom.user.name` still exists alongside `repo.users.*` and
    `repo.context.userName`
  - `repo.context` is assembled twice in every host module (NixOS + HM)

## Desired End State

- User ownership is narrow and global only where the semantics are truly
  cross-host.
- Host-only entitlements and operator wiring live in the host owner.
- Host baseline duplication is reduced where it buys real maintenance value,
  but host composition stays explicit.
- `repo.hosts.*` reads as tracked inventory first, not as a bag of runtime
  objects.
- The remaining compatibility bridge(s) are either removed or made visibly
  transitional and narrow.
- The repo stays dendritic and explicit, without drifting back into hidden
  routing/framework behavior.

## Decision Rules

Use these rules to reject overengineering during implementation:

1. Do not introduce a helper or new option surface unless it removes duplicated
   semantics in at least two real places.
2. Do not hide concrete host imports behind indirection just to make files
   shorter.
3. Prefer moving ownership to the correct owner over creating a generic merge
   mechanism.
4. If a cleanup only changes aesthetics and not maintenance cost, skip it.
5. If a shared abstraction would still require every host to understand it
   before being safely edited, it is probably too clever for this repo.

## Phases

### Phase 0: Baseline and Ownership Audit

Targets:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/users/higorprado.nix`
- `modules/options/inventory.nix`
- `modules/options/repo-runtime-contracts.nix`

Changes:
- no structural edits yet
- capture the exact set of user groups, host-only overlays, duplicated baseline
  imports, and current consumers of `custom.user.name`
- write down which user groups are genuinely cross-host vs host-specific
- write down which fields under `repo.hosts.*` are inventory facts vs runtime
  payload

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name`
- `rg -n "custom\\.user\\.name" modules hardware private scripts tests -g '*.nix' -g '*.sh'`

Diff expectation:
- none; baseline only

Commit target:
- none

### Phase 1: Narrow User Ownership

Targets:
- `modules/users/higorprado.nix`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`

Changes:
- split cross-host user semantics from host-specific entitlements
- keep identity-level semantics in the user owner:
  - base account shape
  - shell
  - primary-user semantics that are truly repo-wide
- move host-specific groups or device entitlements out of the user owner and
  into the relevant host owner if the baseline shows they are not universal
- keep host operator shell wiring in the host owner

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.higorprado.extraGroups`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `./scripts/check-config-contracts.sh`

Diff expectation:
- host-specific groups stop leaking globally if they are not truly universal
- admin semantics remain intact where intended

Commit target:
- `refactor(users): narrow cross-host and host-specific ownership`

### Phase 2: Reduce Baseline Duplication Without Hiding Composition

Targets:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- possibly one or two new explicit baseline modules under `modules/features/core/`

Changes:
- identify the repeated baseline imports shared by all concrete hosts
- extract only the truly universal baseline into one small published module, or
  at most two explicit baselines if desktop/server actually differ materially
- keep feature selection and host-specific imports in each host file
- do not move the full host import list behind a generator or meta-layer

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- smaller repeated host baseline blocks
- no loss of local readability about what makes a host unique

Commit target:
- `refactor(hosts): extract explicit shared baseline imports`

### Phase 3: Clarify Inventory vs Runtime Payload

Targets:
- `modules/options/inventory.nix`
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- possibly a narrow adjacent module under `modules/options/`

Changes:
- move runtime-heavy fields out of `repo.hosts.*` if they are not truly
  inventory-like
- likely candidates:
  - `inputs`
  - `customPkgs`
  - `llmAgents`
  - `hardwareImports`
  - `extraSystemPackages`
- preserve the explicit host composition model by keeping concrete runtime
  wiring close to the host module
- prefer local `let` bindings or a narrow runtime surface over bloating
  `repo.hosts.*`

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.repo.context.hostName`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.repo.context.hostName`

Diff expectation:
- `repo.hosts.*` becomes easier to read as tracked metadata
- runtime payload stays available without being mislabeled as inventory

Commit target:
- `refactor(runtime): separate host inventory from runtime payload`

### Phase 4: Retire or Tighten `custom.user.name`

Targets:
- `modules/options/repo-runtime-contracts.nix`
- `scripts/run-validation-gates.sh`
- `scripts/check-config-contracts.sh`
- any remaining tracked/private consumers identified in Phase 0

Changes:
- determine whether `custom.user.name` can be removed entirely
- if it cannot yet be removed, tighten it further so it is clearly only a
  compatibility bridge and not part of normal feature wiring
- prefer switching scripts to `repo.context.userName` or the tracked host/user
  topology when feasible

Validation:
- `rg -n "custom\\.user\\.name" modules hardware private scripts tests docs -g '*.nix' -g '*.sh' -g '*.md'`
- `./scripts/check-config-contracts.sh`
- `./scripts/run-validation-gates.sh`

Diff expectation:
- fewer duplicate user-control surfaces
- less semantic overlap between inventory, context, and compatibility bridges

Commit target:
- `refactor(runtime): narrow username compatibility bridge`

### Phase 5: Reduce Repeated Context Construction

Targets:
- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- possibly a tiny helper in root `lib/`

Changes:
- reduce duplicated assembly of `repo.context` values for NixOS and HM only if
  it can be done without obscuring host composition
- acceptable shapes:
  - a tiny local host binding reused twice
  - a small root-lib helper that only constructs the attrset
- unacceptable shape:
  - a mini-framework that hides HM/NixOS wiring

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.repo.context`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.repo.context`

Diff expectation:
- less local repetition
- no loss of clarity about where host/user context comes from

Commit target:
- `refactor(hosts): tighten repeated repo context wiring`

### Phase 6: Documentation Consolidation

Targets:
- `docs/for-agents/002-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- relevant human docs only if the runtime story materially changes

Changes:
- describe the tightened ownership model
- document the new host baseline rule if Phase 2 introduces one
- document the inventory/runtime separation if Phase 3 changes that shape
- document the fate of `custom.user.name`

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- living docs describe the actual runtime and ownership boundaries

Commit target:
- `docs(runtime): document tightened organization boundaries`

## Risks

- narrowing user groups too aggressively could break current host capabilities
- extracting shared host baseline too far could recreate a hidden include system
- changing `repo.hosts.*` shape may ripple into scripts and docs more than
  expected
- removing `custom.user.name` too early could break private overrides or
  validation scripts
- reducing repetition in `repo.context` can easily drift into abstraction for
  abstraction's sake

## Definition of Done

- user ownership is narrower and more semantically accurate
- concrete hosts still read as the explicit source of truth
- repeated baseline imports are reduced where that buys real value
- `repo.hosts.*` is cleaner and more inventory-like
- duplicate user-control planes are reduced or visibly transitional
- all changes pass:
  - `./scripts/run-validation-gates.sh`
  - `./scripts/check-docs-drift.sh`
  - targeted `nix eval` / `nix build` checks for both hosts

## Suggested Execution Order

1. Phase 0 first, no edits
2. Phase 1 next, because it is the most clearly real maintenance issue
3. Phase 2 only if the baseline proves the duplication is painful enough
4. Phase 3 after baseline extraction, so inventory/runtime separation is easier
   to judge
5. Phase 4 only after the runtime/user model is stable
6. Phase 5 last, and only if it still looks worthwhile after the earlier
   cleanup
7. Phase 6 at the end
