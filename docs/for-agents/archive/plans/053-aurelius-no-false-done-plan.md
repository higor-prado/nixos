# Aurelius No-False-Done Plan

## Goal

Remove every false sense of completion from the current `aurelius` work. Any
slice that was promoted too early must either be proved properly, downgraded to
partial/deferred, or removed from active runtime. The plan also hardens the
execution workflow so no future slice is labeled "done" before its real user
story is validated.

## Scope

In scope:
- re-audit every `aurelius` slice that has been treated as ready or "kept"
- distinguish strictly between:
  - evaluated
  - built
  - healthy on host
  - usable by the real consumer/operator path
- correct runtime, docs, and active logs when they overstate completion
- remove any "semantic patch" that only makes configuration appear coherent
  without solving the real requirement
- add an explicit proof matrix for each slice before it may be called complete

Out of scope:
- new Attic, Grafana, Prometheus, GitHub runner, or exit-node work
- backup/restic work
- cosmetic refactors with no quality impact
- trying to preserve a slice's "done" label for momentum if the proof is absent

## Current State

- The umbrella execution plan is
  [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md).
- The first quality-sweep attempt is archived as
  [052-aurelius-quality-sweep.md](/home/higorprado/nixos/docs/for-agents/archive/plans/052-aurelius-quality-sweep.md).
- The active progress material currently includes:
  - [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
- Historical sweep output is archived as:
  - [052-aurelius-quality-sweep-progress.md](/home/higorprado/nixos/docs/for-agents/archive/log-tracks/052-aurelius-quality-sweep-progress.md)
- Known concrete failures of execution discipline already identified:
  - a slice was treated as complete when only local host health had been proved
  - a follow-up "fix" tried to realign semantics instead of admitting the slice
    was still incomplete
  - a subplan meant to remove previous gambiarras still admitted a new
    maquiagem-style correction
- The currently affected areas are:
  - the removed Forgejo slice formerly owned by `modules/features/system/forgejo.nix`
  - [modules/features/dev/dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
  - [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
  - [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
  - [docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
  - [docs/for-agents/archive/plans/052-aurelius-quality-sweep.md](/home/higorprado/nixos/docs/for-agents/archive/plans/052-aurelius-quality-sweep.md)
  - [docs/for-agents/archive/log-tracks/052-aurelius-quality-sweep-progress.md](/home/higorprado/nixos/docs/for-agents/archive/log-tracks/052-aurelius-quality-sweep-progress.md)
- The healthy reference remains:
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - the operating docs under `docs/for-agents/000-007`

## Desired End State

- No `aurelius` slice is called complete without proof for its actual claimed
  user story.
- Every slice is classified explicitly as one of:
  - deferred
  - partial
  - complete
- Any slice that lacks proof is downgraded immediately instead of being patched
  cosmetically.
- Runtime semantics, operator docs, and active logs all say the same thing.
- The active plans encode a proof matrix strict enough to prevent another false
  "done".

## Phases

### Phase 0: Freeze Claims

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
- [052-aurelius-quality-sweep.md](/home/higorprado/nixos/docs/for-agents/archive/plans/052-aurelius-quality-sweep.md)
- [052-aurelius-quality-sweep-progress.md](/home/higorprado/nixos/docs/for-agents/archive/log-tracks/052-aurelius-quality-sweep-progress.md)

Changes:
- list every slice currently implied to be ready or kept
- list the exact claim currently attached to each slice
- define the proof required for that claim
- mark every claim with one of:
  - proved
  - partially proved
  - unproved

Validation:
- read the active plans and progress logs together
- verify that each claimed state maps to a concrete proof command

Diff expectation:
- documentation-only truth table for current slice status

Commit target:
- `docs(aurelius): freeze slice claims and proof requirements`

### Phase 1: Downgrade False Completions

Targets:
- active `050` and `052` plan/progress docs
- any human-facing docs that currently imply availability beyond what is proved

Changes:
- remove any "done"/"clean"/"ready" wording that is stronger than the proof
- downgrade slices to `partial` or `deferred` where appropriate
- remove operator workflow guidance for paths that are not fully proved
- make the remaining gaps explicit instead of smoothing them over

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- targeted `rg` checks for stale "done"/"ready"/"works" wording in the touched docs

Diff expectation:
- active docs become conservative and exact

Commit target:
- `refactor(docs): downgrade unproved aurelius claims`

### Phase 2: Remove Cosmetic Runtime Corrections

Targets:
- the removed Forgejo slice formerly owned by `modules/features/system/forgejo.nix`
- [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- any related docs that depended on those cosmetic corrections

Changes:
- identify any change whose only purpose was to make a slice appear coherent
  without solving its real access model
- revert or replace those changes with one of the only acceptable states:
  - real solution
  - explicit partial state
  - explicit defer/removal from active runtime
- keep host-owner discipline intact while doing so

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- runtime proof commands only for slices that still remain active after the downgrade

Diff expectation:
- no fake semantic alignment remains in runtime

Commit target:
- `refactor(aurelius): remove cosmetic false-done fixes`

### Phase 3: Slice-by-Slice Proof Matrix

Targets:
- kept `aurelius` slices in runtime and docs

Changes:
- for each remaining slice, record a proof matrix with four columns:
  - evaluates
  - builds
  - healthy on host
  - usable by intended consumer
- refuse to collapse those columns into one status word
- update active docs so every kept slice shows its real current column boundary

Validation:
- use the exact proof commands for each slice
- include remote host validation for `aurelius`
- include predator-side validation only where the slice claims predator
  consumption or operator workflow

Diff expectation:
- future reviews can reject false completion immediately

Commit target:
- `docs(aurelius): add explicit slice proof matrix`

### Phase 4: Final Revalidation

Targets:
- all touched runtime and docs files

Changes:
- rerun the canonical repo gates
- rerun any slice-specific proofs still relevant after downgrades
- confirm that no active doc or runtime file still implies more than what is
  actually proved

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh all`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`

Diff expectation:
- the active `aurelius` work becomes auditable and trustworthy again

Commit target:
- `refactor(aurelius): restore proof-based completion discipline`

## Risks

- Leaving any slice half-upgraded in the active set would recreate the same
  trust problem.
- Trying to preserve momentum by keeping an unproved slice "mostly done" would
  repeat the execution failure this plan is meant to stop.
- Overly soft wording in docs would again make review harder than necessary.

## Definition of Done

- No active `aurelius` slice is labeled complete without proof for the claimed
  user story.
- No active runtime file contains a cosmetic alignment that stands in for a
  real solution.
- No active doc promises an operator path or service availability that has not
  been proved.
- Active plans and progress logs expose proof gaps explicitly instead of hiding
  them behind broad "done" language.
- The corrected set passes the repo's canonical validation gates.
