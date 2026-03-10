# Repo Quality Improvement Plan

Date: 2026-03-09
Owner: Codex + user
Status: checkpoint completed

## Goal

Raise repo quality from `9.0/10` toward `9.3` to `9.5` without changing the
repo philosophy:

- keep den-native architecture
- keep centralized ownership where it makes sense
- do not split modules only because of LOC
- do not force immutable refs for personal custom packages
- prefer fewer, clearer shared scripts over more automation ceremony

## Baseline

Measured on 2026-03-09:

- tracked shell scripts: `30`
- total `scripts/` LOC: `3037`
- total `modules/` LOC: `2877`
- audit core LOC:
  - `scripts/audit-system-up-to-date.sh`: `284`
  - `scripts/lib/system_up_to_date_audit.sh`: `261`
  - combined: `545`
- host generator LOC:
  - `scripts/new-host-skeleton.sh`: `262`

## Non-Goals

Do not treat these as quality problems for this plan:

- floating refs in personal custom packages
- centralized `fish.nix` or `theme.nix` only because they are large
- adding more CI complexity for GitHub-first workflows

## Execution Rules

Each slice must end with:

1. code change
2. validation
3. before/after diff review where applicable
4. progress log update
5. commit

## Validation Rules

### Mandatory after every meaningful slice

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
```

### Mandatory when Nix behavior can change

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-before
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-before

# apply change

nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-after
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-after

nix store diff-closures /tmp/predator-before /tmp/predator-after
nix store diff-closures /tmp/hm-before /tmp/hm-after
```

### Mandatory when shell scripts change

Run the smallest relevant set:

```bash
shellcheck <changed scripts>
bash scripts/check-changed-files-quality.sh
./scripts/report-maintainability-kpis.sh --skip-gates
```

### Mandatory when `run-validation-gates.sh` or test-pyramid contracts change

```bash
bash tests/scripts/gate-cli-contracts-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
./scripts/run-validation-gates.sh structure
```

## Progress Logging Rules

Every completed slice must be appended to
`docs/for-agents/current/002-repo-quality-improvement-progress.md` with:

1. date
2. goal id
3. exact files changed
4. exact validation commands run
5. diff result summary
6. commit hash and message
7. next blocker or next step

Use facts only. Avoid stale “kept/removed” notes that may become contradictory.

## Quality Goals

### Goal 1: Slim the audit core

Reason:
- the audit core is the biggest remaining tooling hotspot

Targets:
- reduce combined LOC of:
  - `scripts/audit-system-up-to-date.sh`
  - `scripts/lib/system_up_to_date_audit.sh`
  from `545` to `<400`
- keep output contract stable:
  - `summary.md`
  - `inconsistencies.md`
  - `scripts-matrix.csv`
  - `raw/decision-baseline.tsv`
  - `raw/check-status.tsv`
  - `raw/findings.tsv`
- remove duplicated policy/report-generation logic where practical

Preferred approach:
- move repeated TSV/markdown rendering patterns into smaller focused helpers
- replace hardcoded rule text duplication with compact structured data
- delete dead helper branches instead of adding abstractions for obsolete cases

Definition of done:
- audit core under `<400` LOC combined
- audit still runs successfully with:
  - `bash scripts/audit-system-up-to-date.sh --allow-dirty --output /tmp/audit-after-slim`
- before/after outputs are reviewed for contract stability

Checkpoint score:
- approximately `9.15`

### Goal 2: Simplify host skeleton generation

Reason:
- generators are still drift-prone

Targets:
- reduce `scripts/new-host-skeleton.sh` from `262` LOC to `<180`
- separate template content from generation logic
- cover both desktop and server skeleton output with at least `1` fixture-style test

Preferred approach:
- move generated file templates into static tracked templates or compact helper blocks
- keep only argument parsing and template selection in the script

Definition of done:
- generator stays den-native
- generated files still satisfy current host onboarding contracts
- test proves desktop and server output remain valid

Checkpoint score:
- approximately `9.25`

### Goal 3: Clean current/progress bookkeeping

Reason:
- current progress docs should describe current truth, not contradictory history

Targets:
- `0` contradictions in active progress docs
- `0` references to removed scripts outside clearly historical context
- convert append-only cleanup notes into concise phase summaries

Preferred approach:
- keep `001-*` docs as historical execution log
- use `002-*` docs as the current authoritative work log for this phase
- if needed, add short retrospective summaries instead of raw chronological noise

Definition of done:
- active progress doc is accurate on reread
- doc drift check passes

Checkpoint score:
- approximately `9.30`

### Goal 4: Define and enforce the shared script boundary

Reason:
- prevent script creep from returning

Targets:
- every tracked script in `scripts/` must satisfy at least one:
  - called by `scripts/run-validation-gates.sh`
  - enforced by tests/contracts
  - documented as a deliberate shared auxiliary tool
- `0` ambiguous scripts

Preferred approach:
- document the categories directly in this plan and progress log
- if a script does not fit a category, remove it or move it to the private ops area

Definition of done:
- orphan scan shows no ambiguous tracked scripts
- supporting tests/docs agree with the remaining set

Checkpoint score:
- approximately `9.40`

### Goal 5: Reduce audit/report policy duplication

Reason:
- policy strings and report formatting still live in too many places

Targets:
- `1` source of truth for audit decision metadata
- `0` duplicated policy strings across audit/report code where structured data can replace them

Preferred approach:
- encode decision metadata as compact records in one helper
- generate markdown/TSV output from those records

Definition of done:
- editing one audit rule requires one code change, not several
- audit output remains stable enough to diff before/after

Checkpoint score:
- approximately `9.45`

### Goal 6: Preserve the reduced tooling surface

Reason:
- improvement is only real if it stays real

Targets:
- keep tracked shell scripts at `<=30`
- keep total `scripts/` LOC at `<=3000` unless a higher count replaces more complexity elsewhere
- avoid adding new scripts unless one of these is true:
  - it replaces at least one existing script
  - it becomes part of the canonical validation path
  - it is covered by tests and documented as shared tooling

Definition of done:
- KPI report stays at or below the agreed budget after future slices

Checkpoint score:
- approximately `9.50`

## Recommended Execution Order

1. Goal 1
2. Goal 5
3. Goal 2
4. Goal 4
5. Goal 3
6. Goal 6 as an ongoing guardrail

## Commit Strategy

Use one logical change per commit.

## Checkpoint Outcome

Measured after execution on 2026-03-09:

- tracked shell scripts: `30`
- total `scripts/` LOC: `2786`
- audit core LOC:
  - `scripts/audit-system-up-to-date.sh`: `222`
  - `scripts/lib/system_up_to_date_audit.sh`: `107`
  - combined: `329`
- host generator LOC:
  - `scripts/new-host-skeleton.sh`: `153`

Completed goals:

1. Goal 1
   - completed
2. Goal 2
   - completed
3. Goal 3
   - completed
4. Goal 4
   - completed
5. Goal 5
   - completed
6. Goal 6
   - currently satisfied by the KPI budget, shared-script registry, and validation-source enforcement

The repo reached the numeric checkpoint this plan targeted without changing the repo philosophy or forcing non-goal changes.

Suggested commit prefixes:

- `refactor:` for structural simplification
- `fix:` for contract or validation corrections
- `docs:` for plan/progress/doc updates only
- `test:` for new fixture or contract coverage

## Stop Conditions

Stop and reassess if:

- a slice changes Nix closures unexpectedly
- audit output contracts drift in a way that cannot be explained cleanly
- the script budget goes down but validation confidence also goes down
- a simplification requires inventing more ceremony than it removes
