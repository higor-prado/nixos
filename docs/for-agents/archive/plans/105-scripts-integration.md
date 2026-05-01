# Scripts Integration Plan

## Goal

Integrate `check-repo-public-safety.sh` into the `structure` gate stage, move
3 audit leaf checks from `scripts/` root into `scripts/lib/` (clarifying they are
internal library functions, not standalone tools), and add missing shebang to
`check-sd-boot.sh`.

## Scope

In scope:

- Add `check-repo-public-safety.sh` call to `run_structure_gates()` in `run-validation-gates.sh`
- Move `check-declarative-paths.sh` → `scripts/lib/audit_declarative_paths.sh`
- Move `check-flake-tracked.sh` → `scripts/lib/audit_flake_tracked.sh`
- Move `check-nix-deprecations.sh` → `scripts/lib/audit_nix_deprecations.sh`
- Update `scripts/lib/system_up_to_date_audit.sh` — change paths to new lib locations
- Update `docs/for-agents/005-validation-gates.md` — reflect new paths and safety gate
- Add shebang `#!/usr/bin/env bash` to `check-sd-boot.sh`

Out of scope:

- Adding `check-changed-files-quality.sh` to gate runner (kept standalone for pre-push)
- Changing script behavior, exit codes, or output formats
- Touching cerebelo one-shots beyond the shebang fix
- Modifying `report-maintainability-kpis.sh` or `audit-system-up-to-date.sh` logic
- Changing the `structure` gate timeout budget

## Current State

### Gate runner does not include safety check

`run_structure_gates()` runs 10 check scripts but NOT `check-repo-public-safety.sh`.
Users must remember to run it separately before commits.

### Leaf checks pollute scripts/ root

```
scripts/
├── check-declarative-paths.sh    # only called by audit
├── check-flake-tracked.sh        # only called by audit
├── check-nix-deprecations.sh     # only called by audit
```

These 3 scripts have no standalone purpose — they only exist as subroutines of
`audit-system-up-to-date.sh` (via `system_up_to_date_audit.sh`). Their presence
at `scripts/` root creates noise and implies they're independent tools.

### check-sd-boot.sh — no shebang

```bash
# cerebelo helper: mount SD/eMMC FAT partition and print extlinux.conf.
...
```

No `#!/usr/bin/env bash` — not directly executable.

### system_up_to_date_audit.sh references

```bash
scripts/check-declarative-paths.sh	rg
scripts/check-flake-tracked.sh	git rg cut
scripts/check-nix-deprecations.sh	rg
scripts/check-repo-public-safety.sh	rg grep mkdir mktemp wc cp id
```

### Docs references

`docs/for-agents/005-validation-gates.md` line 72:

```
- optional local audit/report generator; uses audit-only leaf checks such as
  `check-declarative-paths.sh`, `check-flake-tracked.sh`,
  `check-nix-deprecations.sh`, and `check-repo-public-safety.sh`
```

## Desired End State

### Gate runner includes safety check

```bash
run_structure_gates() {
  echo "[validation-gates] structure gates"
  run_check_script "check-bare-host-in-includes.sh"
  ...
  run_check_script "check-docs-drift.sh"
  run_check_script "check-repo-public-safety.sh"   # ← ADDED
  run_test_script "run-validation-gates-fixture-test.sh"
  ...
}
```

### scripts/ root — only truly standalone tools

```
scripts/
├── run-validation-gates.sh
├── check-repo-public-safety.sh          # called by gate runner + audit
├── check-bare-host-in-includes.sh       # gate
├── ... (other gate checks)
├── audit-system-up-to-date.sh           # orchestrator
├── check-changed-files-quality.sh       # standalone pre-push
├── check-runtime-smoke.sh               # standalone post-switch
├── check-sd-boot.sh                     # +shebang
├── ... (other standalone tools)
├── lib/
│   ├── ...
│   ├── audit_declarative_paths.sh       # ← moved from root
│   ├── audit_flake_tracked.sh           # ← moved from root
│   ├── audit_nix_deprecations.sh        # ← moved from root
│   └── ...
```

### system_up_to_date_audit.sh — updated paths

```bash
scripts/lib/audit_declarative_paths.sh	rg
scripts/lib/audit_flake_tracked.sh	git rg cut
scripts/lib/audit_nix_deprecations.sh	rg
scripts/check-repo-public-safety.sh	rg grep ...
```

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure` — confirm current state passes
- `./scripts/check-repo-public-safety.sh` — confirm passes
- `git status` — confirm clean

### Phase 1: Add safety check to structure gates

Targets:

- `scripts/run-validation-gates.sh`

Changes:

- Add `run_check_script "check-repo-public-safety.sh"` to `run_structure_gates()`
  (place after `check-docs-drift.sh`, before test scripts)

Validation:

- `./scripts/run-validation-gates.sh structure` — must pass with safety check included
- Verify output shows safety check ran

Commit target:

- `feat(gates): add public safety check to structure stage`

### Phase 2: Move leaf checks to lib/

Targets:

- `scripts/check-declarative-paths.sh` → `scripts/lib/audit_declarative_paths.sh`
- `scripts/check-flake-tracked.sh` → `scripts/lib/audit_flake_tracked.sh`
- `scripts/check-nix-deprecations.sh` → `scripts/lib/audit_nix_deprecations.sh`
- `scripts/lib/system_up_to_date_audit.sh`

Changes:

- `git mv` each leaf check to `scripts/lib/` with `audit_` prefix
- Update `system_up_to_date_audit.sh` — change 3 paths to new locations
- `chmod +x` on moved files (they were executable before)

Validation:

- `git status` — confirm 3 renames tracked
- `grep "check-declarative-paths\|check-flake-tracked\|check-nix-deprecations" scripts/lib/system_up_to_date_audit.sh` — must show new paths
- `bash scripts/audit-system-up-to-date.sh --help` — must not error (validates shell parsing)

Commit target:

- `refactor(scripts): move audit leaf checks to lib/`

### Phase 3: Add shebang to check-sd-boot.sh

Targets:

- `scripts/check-sd-boot.sh`

Changes:

- Add `#!/usr/bin/env bash` as first line
- (Optional) `chmod +x` — already needs it from previous audit finding

Validation:

- `head -1 scripts/check-sd-boot.sh` — shows shebang
- `bash -n scripts/check-sd-boot.sh` — valid syntax

Commit target:

- `fix(scripts): add shebang to check-sd-boot.sh`

### Phase 4: Update docs

Targets:

- `docs/for-agents/005-validation-gates.md`

Changes:

- Line 72: update leaf check paths `check-declarative-paths.sh` → `scripts/lib/audit_declarative_paths.sh`
- Add `check-repo-public-safety.sh` to structure gate listing (line ~24-34 area, or note it's now integrated)
- Line ~81: `check-sd-boot.sh` — note it's a cerebelo helper (path unchanged, stays at root)

Validation:

- `./scripts/run-validation-gates.sh structure` — docs-drift must pass
- `./scripts/check-repo-public-safety.sh` — must pass

Commit target:

- `docs: update validation gates docs for scripts integration`

### Phase 5: Final validation

Validation:

- `./scripts/run-validation-gates.sh structure` — all 14 gates pass
- `./scripts/check-repo-public-safety.sh` — pass
- `bash -n scripts/lib/audit_declarative_paths.sh` — valid syntax
- `bash -n scripts/lib/audit_flake_tracked.sh` — valid syntax
- `bash -n scripts/lib/audit_nix_deprecations.sh` — valid syntax
- `head -1 scripts/check-sd-boot.sh` — has shebang
- `ls scripts/` — 19 .sh files at root (was 22)
- `ls scripts/lib/` — 10 files (was 7)

## Risks

- **audit-system-up-to-date.sh may not have been tested recently**. The plan
  only changes paths in `system_up_to_date_audit.sh`, not logic. Shell syntax
  check (`bash -n`) covers parsing errors.
- **No test fixture covers the audit script**. The leaf checks are only validated
  by manual audit runs. The git mv + path update is mechanical — risk is low.
- **check-sd-boot.sh has no tests**. Adding shebang is purely cosmetic — no
  behavior change.

## Definition of Done

- [ ] `check-repo-public-safety.sh` called by `structure` gate stage
- [ ] 3 leaf checks moved to `scripts/lib/` with `audit_` prefix
- [ ] `system_up_to_date_audit.sh` references updated to new paths
- [ ] `check-sd-boot.sh` has shebang
- [ ] `docs/for-agents/005-validation-gates.md` updated
- [ ] `./scripts/run-validation-gates.sh structure` passes (all 14 gates + safety)
- [ ] `./scripts/check-repo-public-safety.sh` passes
- [ ] No broken references to old leaf check paths in docs or scripts
- [ ] `scripts/` root: 19 .sh files, `scripts/lib/`: 10 files
