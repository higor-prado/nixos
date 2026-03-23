# Aurelius Execution Reset

## Goal

Reset the current `aurelius` work back to the repository workflow standard: use
the living docs as the source of truth, use `predator` as the concrete shape
reference for host composition, remove the half-baked host-owner drift, and
continue only in small validated slices.

## Scope

In scope:
- remove the bad `aurelius` host-owner drift introduced by the recent work
- restore a clean host owner shape that matches the repo pattern already proven
  in `predator`
- keep only slices that are complete, narrow, and already validated
- re-evaluate any secret-dependent service work before keeping it in tracked
  runtime
- update active plan/progress docs to reflect the reset

Out of scope:
- inventing a new host-private pattern
- normalizing inline module hacks, `pathExists` gating, or secret-path wiring in
  tracked host composition
- backup work for `aurelius`
- finishing every deferred service in one shot

## Current State

- The current active plan is
  [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md).
- The healthy shape reference is
  [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix).
- The current bad regression is in
  [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix):
  - secret-dependent services were pushed into tracked host composition
  - inline module payloads were mixed into import lists
  - tracked docs started to normalize that bad shape
- The repo docs already define the correct rules:
  - [000-operating-rules.md](/home/higorprado/nixos/docs/for-agents/000-operating-rules.md)
  - [003-module-ownership.md](/home/higorprado/nixos/docs/for-agents/003-module-ownership.md)
  - [006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md)
- Several earlier slices are already good and should not be thrown away if their
  shape stays clean:
  - docker foundation
  - remote dev baseline
  - cross-arch `dev-devenv` fix
  - Mosh
  - node exporter
  - Forgejo

## Desired End State

- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix) is clean again:
  - grouped `nixos*` lists by concern
  - grouped `hm*` lists by concern
  - no inline modules in import lists
  - no secret-file wiring in tracked host composition
- Tracked runtime keeps only slices that are:
  - cleanly owned
  - fully configured
  - validated
- Any secret-dependent service work that does not yet have a clean repo-native
  shape is removed from the active tracked runtime instead of being left in an
  ugly transitional form.
- The active docs describe only the clean shape that actually survives.

## Phases

### Phase 0: Baseline

Targets:
- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)

Changes:
- inventory the exact `aurelius` drift against the `predator` reference
- classify each in-flight slice as:
  - keep now
  - drop now
  - defer cleanly

Validation:
- read the current tracked host owners and active progress log
- no runtime changes in this phase

Diff expectation:
- plan-only reset baseline

Commit target:
- `docs(aurelius): record execution reset`

### Phase 1: Remove Bad Host-Owner Drift

Targets:
- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- any newly added tracked docs/examples that normalize the bad shape

Changes:
- remove secret-dependent wiring that was shoved into the tracked host owner
- remove inline module attrsets mixed into import lists
- restore the host owner to the same style discipline already used in
  `predator`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- the host owner becomes readable and policy-compliant again

Commit target:
- `refactor(aurelius): remove host-owner drift`

### Phase 2: Keep Only Clean Completed Slices

Targets:
- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- clean feature owners under `modules/features/system/`
- [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) if a clean operator-side slice remains there

Changes:
- keep only the slices that are already clean and validated
- if `prometheus` can stay with the same clean shape as the other service
  owners, keep it
- if any new service owner still depends on transitional hackery, drop it from
  the active tracked runtime for now

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- remote `aurelius` validation through `nh os test` from the tracked repo root
- `nix store diff-closures` on `aurelius` if the evaluated system closure changes

Diff expectation:
- only finished, policy-compliant slices remain active

Commit target:
- `refactor(aurelius): keep only clean validated slices`

### Phase 3: Resume Service Work in Small Slices

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)

Changes:
- resume the `050` roadmap only after the reset is complete
- reintroduce deferred services one by one, only when they have:
  - a clear owner
  - a clean host shape
  - a validation path

Validation:
- same slice-level validation as above

Diff expectation:
- the plan resumes from a clean baseline instead of compounding a bad one

Commit target:
- no commit in this phase by default; this is the handoff point back to `050`

## Risks

- Throwing away too much could erase good completed slices along with the bad
  ones.
- Throwing away too little would leave the host owner in a still-compromised
  state.
- Secret-dependent services are the main trap: they can easily tempt another
  transitional tracked hack if they are resumed too early.

## Definition of Done

- `aurelius` matches the repo host-owner pattern again.
- No tracked host file contains inline secret-dependent module glue.
- Only clean validated slices remain active in tracked runtime.
- The active docs reflect the cleaned state accurately.
