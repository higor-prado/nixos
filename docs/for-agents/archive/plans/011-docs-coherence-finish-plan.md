# Docs Coherence Finish Plan

Date: 2026-03-10
Status: planned

Source review:
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/002-den-architecture.md`
- `docs/for-agents/current/012-user-bridge-and-host-metadata-progress.md`

Execution log:
- `docs/for-agents/current/013-docs-coherence-finish-progress.md`

## Goal

Close the remaining tooling/docs coherence gaps so the live repo, the agent docs,
the host generator, and the fixtures all describe the same architecture.

This plan is intentionally scoped to coherence, not architecture redesign.

## Remaining Gaps To Fix

## 1. HM rule drift in operating docs

Problem:
- `docs/for-agents/000-operating-rules.md`
  still says HM config goes inside `den.aspects.X.nixos` using
  `home-manager.users.${userName}`
- the live repo and the den-native architecture doc use `.homeManager` as the
  normal path

Why it matters:
- this is a top-level operating rule
- an agent following it literally would implement the wrong pattern

Target state:
- operating rules explicitly say:
  - use `den.aspects.<name>.homeManager`
  - rely on den HM routing
  - do not hand-wire `home-manager.users.<userName>` from feature modules

## 2. Generator/templates/fixtures still emit manual hostname wiring

Problem:
- `templates/new-host-skeleton/desktop-hardware.nix.tpl`
  still writes `networking.hostName = "__HOST_NAME__";`
- `templates/new-host-skeleton/server-hardware.nix.tpl`
  does the same
- matching fixtures in
  `tests/fixtures/new-host-skeleton`
  still encode the old behavior

Why it matters:
- live hosts now use `den._.hostname`
- the generator is now recreating a pattern the repo just removed

Target state:
- generator output uses `den._.hostname` through the host aspect
- hardware skeletons no longer declare `networking.hostName`
- fixture outputs match the new shape

## 3. Repo map is slightly stale

Problem:
- `docs/for-agents/001-repo-map.md`
  still under-describes `lib`
- it does not mention `lib/primary-tracked-user.nix`

Why it matters:
- the repo map is supposed to be the authoritative navigation doc

Target state:
- the map reflects the actual contents and ownership of `lib/`

## 4. Runtime smoke boundary is still explained, but not fully resolved

Problem:
- `docs/for-agents/005-validation-gates.md`
  still has to describe `scripts/check-runtime-smoke.sh`
  as a special predator-only tracked auxiliary tool
- tests such as
  `tests/scripts/gate-cli-contracts-test.sh`
  still carry contract surface for it

Why it matters:
- this is coherent enough to work, but not completely clean
- docs quality cannot reach “fully aligned” while this boundary remains undecided

Target state:
- one explicit decision:
  - keep it tracked and document it as a deliberate local auxiliary tool, or
  - remove/move it and delete its tracked docs/tests references

Important note:
- this plan may stop short of deleting the script if the workflow decision is
  not made yet
- if the decision remains open, docs should say that explicitly instead of
  implying finality

## 5. Some `current/` docs are half history, half current-state guidance

Problem:
- files under `docs/for-agents/current`
  are useful, but some still read like present-tense state even when they are
  mostly historical progress logs

Main examples to review:
- `docs/for-agents/current/012-user-bridge-and-host-metadata-progress.md`
- any related current logs that still state resolved items as open architectural findings

Why it matters:
- this is a coherence issue, not a correctness failure
- “current” docs should either be clearly active state or clearly historical

Target state:
- each `current/` file is one of:
  - active current-state diagnosis
  - active progress tracker
  - clearly historical closeout log

## Scope

In scope:
- agent docs
- human workflow docs
- generator templates
- generator fixtures/tests
- validation docs for runtime smoke if needed

Out of scope:
- changing the architecture further
- deleting runtime smoke unless that decision is explicitly taken during execution
- rewriting old historical progress logs that are not causing current confusion

## Execution Order

1. Fix the HM rule in the operating docs
2. Fix generator/templates/fixtures for hostname ownership
3. Refresh repo map and structure docs
4. Clarify runtime smoke docs/tests boundary
5. Normalize current-state docs that still mix history with active guidance

This order is deliberate:
- item 1 fixes the highest-risk instruction first
- item 2 prevents future stale scaffolding from being generated
- item 3 updates the main navigation layer
- items 4 and 5 are cleanup/clarity work after the structural docs are correct

## Phase 1: Operating Rule Reconciliation

Files:
- `docs/for-agents/000-operating-rules.md`
- possibly `docs/for-agents/002-den-architecture.md` if wording needs minor reinforcement

Change:
- replace the stale HM rule with the live den-native `.homeManager` rule

Validation:
```bash
./scripts/check-docs-drift.sh
```

Commit target:
- `docs: align operating rules with den home-manager model`

## Phase 2: Generator / Fixture Hostname Reconciliation

Files:
- `templates/new-host-skeleton/desktop-hardware.nix.tpl`
- `templates/new-host-skeleton/server-hardware.nix.tpl`
- `scripts/new-host-skeleton.sh` if the next-steps text needs updating
- `tests/fixtures/new-host-skeleton`
- `tests/scripts/new-host-skeleton-fixture-test.sh` if expectations need updating
- host-onboarding docs that still mention hostname ownership in hardware defaults

Change:
- remove manual `networking.hostName` from generated hardware skeletons
- ensure generated host modules include `den._.hostname`
- update fixture output to match

Validation:
```bash
bash tests/scripts/new-host-skeleton-fixture-test.sh
./scripts/check-docs-drift.sh
```

Diff check:
- compare generated output against updated fixtures

Commit target:
- `refactor: align host skeletons with den hostname ownership`

## Phase 3: Repo Map Refresh

Files:
- `docs/for-agents/001-repo-map.md`
- related structure docs only if they reference the old ownership

Change:
- add `primary-tracked-user.nix`
- ensure `lib/` description reflects the current helper set

Validation:
```bash
./scripts/check-docs-drift.sh
```

Commit target:
- `docs: refresh repo map for current helper layout`

## Phase 4: Runtime Smoke Boundary Clarification

Files:
- `docs/for-agents/005-validation-gates.md`
- `tests/pyramid/shared-script-registry.tsv`
- `tests/scripts/gate-cli-contracts-test.sh`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/004-antipattern-priority-order.md`

Two acceptable end states:

1. Keep tracked:
   - docs call it a deliberate predator-local auxiliary tool
   - tests only validate CLI contract, not pretend it is shared generic tooling

2. Remove from repo:
   - docs/tests/registry references removed

Validation:
```bash
./scripts/check-docs-drift.sh
bash tests/scripts/gate-cli-contracts-test.sh
```

Commit target if retained:
- `docs: clarify runtime smoke boundary`

Commit target if removed:
- `refactor: remove tracked runtime smoke helper`

## Phase 5: Current Docs Normalization

Files:
- `docs/for-agents/current` files touched by this cleanup
- especially `docs/for-agents/current/012-user-bridge-and-host-metadata-progress.md`

Change:
- mark resolved trackers clearly as closeout logs if they are no longer active
- avoid present-tense statements that are no longer true

Validation:
```bash
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
```

Commit target:
- `docs: normalize current-state logs after bridge cleanup`

## Testing Discipline

Every phase:
```bash
./scripts/check-docs-drift.sh
```

When generator/fixtures change:
```bash
bash tests/scripts/new-host-skeleton-fixture-test.sh
```

When runtime-smoke docs/tests change:
```bash
bash tests/scripts/gate-cli-contracts-test.sh
```

If a docs-only phase changes any user-visible validation workflow text:
```bash
bash scripts/check-changed-files-quality.sh
```

## Success Criteria

Mandatory:
- no top-level operating doc contradicts the live den HM pattern
- generator/templates/fixtures no longer reintroduce manual hostname ownership
- repo map reflects the current helper set
- docs and registries describe runtime smoke in a way that matches reality

Nice to have:
- `current/` docs are cleaner about what is active state versus historical progress

## Main Risks

1. Fixing docs but leaving generator fixtures stale, which recreates the same drift.
2. Over-editing historical progress logs and destroying useful migration history.
3. Describing runtime smoke as “resolved” before the workflow decision is actually made.

## Recommended Commit Sequence

1. `docs: align operating rules with den home-manager model`
2. `refactor: align host skeletons with den hostname ownership`
3. `docs: refresh repo map for current helper layout`
4. `docs: clarify runtime smoke boundary`
5. `docs: normalize current-state logs after bridge cleanup`
