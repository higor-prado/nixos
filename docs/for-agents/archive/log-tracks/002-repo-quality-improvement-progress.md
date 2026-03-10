# Repo Quality Improvement Progress

Date started: 2026-03-09
Status: checkpoint completed

## Scope

Track execution of
`docs/for-agents/plans/002-repo-quality-improvement-plan.md`.

## Baseline

Measured before execution starts:

- tracked shell scripts: `30`
- total `scripts/` LOC: `3037`
- total `modules/` LOC: `2877`
- audit core combined LOC: `545`
- `new-host-skeleton.sh` LOC: `262`
- repo score at plan start: `9.0/10`

## Goals

1. Slim the audit core to `<400` LOC combined.
2. Reduce `new-host-skeleton.sh` to `<180` LOC and add fixture coverage.
3. Keep active progress docs contradiction-free.
4. Make the shared script boundary explicit and enforceable.
5. Reduce audit/report policy duplication.
6. Preserve the reduced tooling surface at `<=30` scripts and `<=3000` LOC.

## Current State

- completed:
  - Goal 1: audit core reduced under target and deduplicated
  - Goal 2: host skeleton generator reduced under target with fixture coverage
  - Goal 3: current/progress docs normalized to match tracked state
  - Goal 4: shared-script boundary documented and enforced
  - Goal 5: audit decision metadata moved to a tracked registry
  - Goal 6: tooling surface remains within target budget
- active:
  - none

## Logging Template

### YYYY-MM-DD

- Goal:
- Files changed:
- Validation:
- Diff review:
- Result:
- Commit:
- Next step:

## Log

### 2026-03-09

- Goal:
  - checkpoint before Goal 1 execution
- Files changed:
  - `modules/hosts/aurelius.nix`
  - `flake.lock`
- Validation:
  - `./scripts/run-validation-gates.sh aurelius`
  - `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.services.smartd.enable`
  - `./scripts/check-docs-drift.sh`
- Diff review:
  - `modules/hosts/aurelius.nix` restores `services.smartd.enable = lib.mkForce false` for Aurelius
  - `flake.lock` updates `home-manager` and `dms`
- Result:
  - Aurelius switch failure root cause identified as `smartd.service` failing on an Oracle block volume with no SMART support
  - host override restored locally so Aurelius config evaluates with `services.smartd.enable = false`
- Commit:
  - `41b818d` `fix: restore aurelius smartd override and update inputs`
- Next step:
  - start Goal 1 by shrinking the audit core while keeping its output contract stable

### 2026-03-09

- Goal:
  - Goal 1 slice 1: shrink the audit core while preserving the current report contract
- Files changed:
  - `scripts/audit-system-up-to-date.sh`
  - `scripts/lib/system_up_to_date_audit.sh`
- Validation:
  - `shellcheck scripts/audit-system-up-to-date.sh scripts/lib/system_up_to_date_audit.sh`
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-goal1-before`
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-goal1-after3`
  - `./scripts/run-validation-gates.sh structure`
- Diff review:
  - `diff -u` for `scripts-matrix.csv` and `raw/decision-baseline.tsv` is clean
  - normalized `summary.md` is identical after ignoring the expected output-directory path change
  - normalized `inconsistencies.md` is identical after trimming trailing whitespace
- Result:
  - audit core reduced from `545` LOC to `299` LOC combined
  - output contract preserved:
    - `summary.md`
    - `inconsistencies.md`
    - `scripts-matrix.csv`
    - `raw/decision-baseline.tsv`
    - `raw/check-status.tsv`
    - `raw/findings.tsv`
- Commit:
  - `462d31c` `refactor: slim shared audit core`
- Next step:
  - commit Goal 1 slice 1, then continue Goal 1 by reducing remaining duplication in the audit/report path

### 2026-03-09

- Goal:
  - Goal 1 slice 2: remove duplicated audit inventory metadata from the audit entrypoint
- Files changed:
  - `scripts/audit-system-up-to-date.sh`
  - `scripts/lib/system_up_to_date_audit.sh`
- Validation:
  - `shellcheck scripts/audit-system-up-to-date.sh scripts/lib/system_up_to_date_audit.sh`
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-goal1-after4`
- Diff review:
  - `diff -u` for `scripts-matrix.csv` and `raw/decision-baseline.tsv` is clean
  - normalized `summary.md` is identical to the previous slice
  - normalized `inconsistencies.md` is identical to the previous slice
- Result:
  - audit script inventory and dependency metadata now come from one shared source
  - audit core remains under target at `307` LOC combined
- Commit:
  - `b005649` `refactor: dedupe shared audit inventory`
- Next step:
  - re-run repo gates, commit slice 2, then move to Goal 2 (`new-host-skeleton.sh`)

### 2026-03-09

- Goal:
  - Goal 2 slice 1: move generator templates out of the script and add fixture coverage
- Files changed:
  - `scripts/new-host-skeleton.sh`
  - `templates/new-host-skeleton/desktop-hardware.nix.tpl`
  - `templates/new-host-skeleton/server-hardware.nix.tpl`
  - `templates/new-host-skeleton/desktop-module.nix.tpl`
  - `templates/new-host-skeleton/server-module.nix.tpl`
  - `tests/fixtures/new-host-skeleton/desktop/hardware/zeus/default.nix`
  - `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
  - `tests/fixtures/new-host-skeleton/server/hardware/ci-runner/default.nix`
  - `tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix`
  - `tests/scripts/new-host-skeleton-fixture-test.sh`
- Validation:
  - `shellcheck scripts/new-host-skeleton.sh tests/scripts/new-host-skeleton-fixture-test.sh`
  - `bash tests/scripts/new-host-skeleton-fixture-test.sh`
  - `./scripts/check-extension-contracts.sh`
  - `./scripts/run-validation-gates.sh structure`
  - `./scripts/check-docs-drift.sh`
- Diff review:
  - fixture test uses `diff -u` against tracked expected desktop and server outputs
  - generated desktop and server skeleton files remained byte-for-byte aligned with fixtures
- Result:
  - `scripts/new-host-skeleton.sh` reduced from `262` LOC to `153` LOC
  - template content moved into tracked files, separating generator logic from Nix output shape
  - generator now creates `modules/hosts/` automatically instead of assuming it already exists
- Commit:
  - `c89c1f5` `refactor: template host skeleton generation`
- Next step:
  - normalize the active progress docs so current state and historical execution no longer drift

### 2026-03-09

- Goal:
  - Goal 3 slice 1: normalize active progress docs so tracked state matches current reality
- Files changed:
  - `docs/for-agents/current/001-repo-refactor-progress.md`
  - `docs/for-agents/current/002-repo-quality-improvement-progress.md`
- Validation:
  - `./scripts/check-docs-drift.sh`
- Diff review:
  - `001` converted from contradictory append-only transcript to completed summary
  - `002` status, current state, and latest commit markers now match the tracked repo state
- Result:
  - active progress docs no longer contain stale pending markers for completed slices
  - `001` is now safe to read as historical summary without contradicting removed scripts or old intermediate decisions
- Commit:
  - `c099358` `docs: normalize progress tracking state`
- Next step:
  - commit Goal 3 slice 1, then review remaining shared-script boundary docs for Goal 4

### 2026-03-09

- Goal:
  - Goal 4 slice 1: define and enforce the top-level shared-script boundary
- Files changed:
  - `docs/for-agents/005-validation-gates.md`
  - `scripts/check-validation-source-of-truth.sh`
  - `tests/pyramid/shared-script-registry.tsv`
- Validation:
  - `shellcheck scripts/check-validation-source-of-truth.sh`
  - `./scripts/check-validation-source-of-truth.sh`
  - `bash scripts/check-changed-files-quality.sh`
  - `./scripts/report-maintainability-kpis.sh --skip-gates`
  - `./scripts/run-validation-gates.sh structure`
  - `./scripts/check-docs-drift.sh`
- Diff review:
  - registry enumerates every top-level tracked script exactly once
  - validation-source check now enforces that each script is either in the gate runner, audit inventory, or documented as a shared auxiliary tool
  - docs now describe the category model and the authoritative registry location
- Result:
  - top-level shared scripts no longer rely on implicit ownership or tribal knowledge
  - ambiguous-script count for tracked top-level shell entrypoints is now `0`
- Commit:
  - `e5b8b4b` `docs: enforce shared script boundary registry`
- Next step:
  - commit Goal 4 slice 1, then review whether Goal 5 still requires a separate pass after the earlier audit-core consolidation

### 2026-03-09

- Goal:
  - Goal 5 slice 1: move audit decision metadata to a tracked registry and drive section rendering from shared tables
- Files changed:
  - `scripts/lib/system_up_to_date_audit.sh`
  - `scripts/check-test-pyramid-contracts.sh`
  - `tests/pyramid/system-up-to-date-audit-decisions.tsv`
- Validation:
  - `shellcheck scripts/lib/system_up_to_date_audit.sh scripts/check-test-pyramid-contracts.sh`
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-goal5-before`
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-goal5-after`
  - `bash scripts/check-changed-files-quality.sh`
  - `./scripts/report-maintainability-kpis.sh --skip-gates`
  - `./scripts/run-validation-gates.sh structure`
- Diff review:
  - `diff -u` for `scripts-matrix.csv` and `raw/decision-baseline.tsv` is clean
  - normalized `summary.md` is identical after ignoring the expected output-directory path change
  - normalized `inconsistencies.md` is identical
- Result:
  - audit decision metadata now lives in one tracked TSV registry
  - audit inconsistencies sections are rendered from one shared section table instead of repeated callsites
  - structure gates now validate the decision registry shape
- Commit:
  - `ec939be` `refactor: externalize audit decision metadata`
- Next step:
  - verify current KPI budget and close the plan checkpoint if the numbers still hold

### 2026-03-09

- Goal:
  - Goal 6 checkpoint: verify the reduced tooling surface still satisfies the budget after Goals 1-5
- Files changed:
  - `docs/for-agents/plans/002-repo-quality-improvement-plan.md`
  - `docs/for-agents/current/002-repo-quality-improvement-progress.md`
- Validation:
  - `find scripts -type f -name '*.sh' | wc -l`
  - `find scripts -type f -name '*.sh' -print0 | xargs -0 wc -l | tail -n1`
  - `./scripts/report-maintainability-kpis.sh --skip-gates`
  - `./scripts/check-docs-drift.sh`
- Diff review:
  - plan and progress docs now record the actual post-execution metrics instead of only the initial baseline
  - no runtime or Nix behavior changed; this slice is documentation-only
- Result:
  - tracked shell scripts: `30`
  - total `scripts/` LOC: `2786`
  - audit core combined LOC: `329`
  - `new-host-skeleton.sh` LOC: `153`
  - Goal 6 budget is satisfied without adding another enforcement script
- Commit:
  - pending
- Next step:
  - commit the checkpoint summary and stop the plan unless a new quality target is defined
