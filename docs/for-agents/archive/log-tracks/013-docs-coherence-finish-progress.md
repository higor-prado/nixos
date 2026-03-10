# Docs Coherence Finish Progress

Date: 2026-03-10
Status: completed

Plan:
- `docs/for-agents/plans/011-docs-coherence-finish-plan.md`

## Baseline

Known remaining coherence gaps:
- stale HM operating rule in `000-operating-rules.md`
- host skeleton templates/fixtures still emit manual `networking.hostName`
- repo map under-describes `lib/`
- runtime smoke is still a documented tracked special case
- some `current/` docs still mix historical and present-tense state

## Phase Checklist

- [x] Phase 1: operating rule reconciliation
- [x] Phase 2: generator / fixture hostname reconciliation
- [ ] Phase 3: repo map refresh
- [x] Phase 3: repo map refresh
- [x] Phase 4: runtime smoke boundary clarification
- [x] Phase 5: current docs normalization

## Notes

- This plan is about coherence and drift removal, not more architectural change.
- Runtime smoke may remain tracked if the workflow decision is to keep it.

## Phase 1 Result

Files updated:
- `docs/for-agents/000-operating-rules.md`

Outcome:
- the top-level HM operating rule now matches the live den-native model
- tracked feature modules are instructed to use `.homeManager`
- the stale `home-manager.users.${userName}` feature wiring rule is gone

Validation:
- `./scripts/check-docs-drift.sh` -> pending after combined phase 1/2 slice

## Phase 2 Result

Files updated:
- `templates/new-host-skeleton/desktop-hardware.nix.tpl`
- `templates/new-host-skeleton/server-hardware.nix.tpl`
- `templates/new-host-skeleton/desktop-module.nix.tpl`
- `templates/new-host-skeleton/server-module.nix.tpl`
- `tests/fixtures/new-host-skeleton/desktop/hardware/zeus/default.nix`
- `tests/fixtures/new-host-skeleton/server/hardware/ci-runner/default.nix`
- `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
- `tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix`

Outcome:
- generated hosts now inherit hostname through `den._.hostname`
- generated hardware skeletons no longer reintroduce manual `networking.hostName`
- fixture output was updated to keep the generator diff test authoritative

Validation:
- `./scripts/check-docs-drift.sh` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass

## Phase 3 Result

Files updated:
- `docs/for-agents/001-repo-map.md`

Outcome:
- the repo map now describes the full tracked helper set under `lib`
- `lib/primary-tracked-user.nix` is now discoverable from the main navigation doc

## Phase 4 Result

Files updated:
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/004-antipattern-priority-order.md`

Outcome:
- runtime smoke is now documented as a deliberate tracked local-tool exception
- the docs no longer imply that its boundary status is unresolved inside the validation docs
- the remaining cleanup opportunity is now framed as an optional future simplification

## Phase 5 Result

Files updated:
- `docs/for-agents/current/012-user-bridge-and-host-metadata-progress.md`

Outcome:
- the historical progress log is now marked as a closeout log
- baseline statements that were reading like current truth are now labeled as baseline/historical state

## Final Validation

- `./scripts/check-docs-drift.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass

## Closeout

The docs coherence plan is complete.
The remaining `check-runtime-smoke.sh` question is now a workflow simplification
decision, not a docs drift problem.
