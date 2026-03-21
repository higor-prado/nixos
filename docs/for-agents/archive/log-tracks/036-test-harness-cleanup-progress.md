# Test Harness Cleanup Progress

Related plan:
- [036-test-harness-cleanup.md](../plans/036-test-harness-cleanup.md)

## Baseline

- `check-extension-simulations.sh` only evaluated a synthetic
  `extendModules` override on `aurelius`.
- It did not protect a distinct runtime invariant beyond the real
  eval/build gates already run by `run-validation-gates.sh all`.
- The script still forced fixture and registry surface area for weak signal.

## Phase 0 Audit

Commands run:
- `sed -n '1,260p' docs/for-agents/plans/036-test-harness-cleanup.md`
- `sed -n '1,220p' scripts/check-extension-simulations.sh`
- `rg -n "check-extension-simulations|extension-simulations" README.md AGENTS.md docs scripts tests .github --glob '!docs/for-agents/archive/**'`

Findings:
- The script only asserted that a synthetic `systemDrv` path looked valid.
- Real host eval/build gates already prove stronger invariants.
- Keeping it would preserve noise in the gate runner, fixture runner, and
  shared script registry for little value.

## Outcome

- Deleted `scripts/check-extension-simulations.sh`.
- Removed it from `run-validation-gates.sh`, the fixture runner test, the
  shared script registry, and the live validation docs.
- Revalidated:
  - `bash tests/scripts/run-validation-gates-fixture-test.sh`
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh structure`
  - `./scripts/run-validation-gates.sh all`
