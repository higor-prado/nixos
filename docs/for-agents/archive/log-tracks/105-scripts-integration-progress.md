# Scripts Integration Progress

## Status

Completed

## Related Plan

- [105-scripts-integration.md](/home/higorprado/nixos/docs/for-agents/plans/105-scripts-integration.md)

## Baseline

- Validation gates: PASS
- Safety check: PASS
- Working tree: clean

## Slices

### Phase 1 — Add safety check to structure gates

- Added `run_check_script "check-repo-public-safety.sh"` to `run_structure_gates()`
- Updated `run-validation-gates-fixture-test.sh` with stub + assertion
- Commit: `feat(gates): add public safety check to structure stage`
- Follow-up: `fix(tests): add safety check to fixture test scripts list`

### Phase 2 — Move audit leaf checks to lib/

- `git mv check-declarative-paths.sh → lib/audit_declarative_paths.sh`
- `git mv check-flake-tracked.sh → lib/audit_flake_tracked.sh`
- `git mv check-nix-deprecations.sh → lib/audit_nix_deprecations.sh`
- Updated `system_up_to_date_audit.sh` references
- Commit: `refactor(scripts): move audit leaf checks to lib/`

### Phase 3 — Add execute permissions

- `chmod +x check-sd-boot.sh fix-cerebelo-nvme.sh` (both had shebangs but no +x)
- Commit: `fix(scripts): add execute permission to cerebelo helper scripts`

### Phase 4 — Update docs + registry

- Updated `005-validation-gates.md`: new paths, safety check in gate table
- Fixed `tests/pyramid/shared-script-registry.tsv`: new paths for leaf checks
- Commit: `docs: update validation gates docs for scripts integration`
- Commit: `fix(tests): update script registry for moved audit leaf checks`
- Commit: `docs: use full paths for audit leaf checks in validation gates doc`

### Phase 5 — Final validation

- `./scripts/run-validation-gates.sh structure`: ALL PASS (incl. safety check)
- `scripts/` root: 23 .sh files (was 22; +safety in gate, -3 leaf checks moved)
- `scripts/lib/`: 10 .sh files (was 7; +3 audit leaf checks)
- Zero stale references in scripts, docs, or registry

## Final State

### Gate runner now includes safety check

```
structure gates (now 11 check scripts + 4 test scripts):
  1. check-bare-host-in-includes.sh
  ...
  10. check-docs-drift.sh
  11. check-repo-public-safety.sh   ← NEW
  + 4 fixture test scripts
```

### scripts/ root — 3 fewer standalone files

Leaf checks moved to `scripts/lib/` with `audit_` prefix:

- `audit_declarative_paths.sh`
- `audit_flake_tracked.sh`
- `audit_nix_deprecations.sh`

### Cerebelo helpers — now executable

- `check-sd-boot.sh`: `-rwxr-xr-x` ✅
- `fix-cerebelo-nvme.sh`: `-rwxr-xr-x` ✅

### What remains open

Nothing — integration complete.
