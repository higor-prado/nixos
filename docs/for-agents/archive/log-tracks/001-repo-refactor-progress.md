# Repo Refactor Progress

Date started: 2026-03-09
Status: completed

## Scope

Execution log summary for
`docs/for-agents/plans/001-repo-refactor-plan.md`.

## Final Outcome

The refactor plan was completed in four broad phases:

1. Ownership cleanup
   - moved optional user-group ownership out of `system-base.nix`
   - removed duplicate primary-user group ownership on `predator`
2. Networking cleanup
   - split shared networking from resolved/avahi discovery policy
   - removed Aurelius host-level `mkForce` undoing for those services
3. Contract alignment
   - aligned public-safety docs, allowlist, and den architecture notes with the tracked canonical-user exception
4. Tooling reduction
   - reduced tracked scripts from `43` to `30`
   - reduced tracked `scripts/` LOC from `4397` to `3037`
   - removed orphaned host-local parity/remediation/deploy helpers from shared repo tooling

## Validation Summary

The refactor was validated incrementally with:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/run-validation-gates.sh predator`
- `./scripts/run-validation-gates.sh aurelius`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/report-maintainability-kpis.sh --skip-gates`
- targeted `shellcheck` runs on touched scripts
- targeted `nix build` / `nix eval` checks for affected hosts
- `nix store diff-closures` for behavior-preserving cleanup slices

## Result

- repo contracts are tighter and more aligned with tracked state
- host composition is cleaner
- public-safety policy and docs are internally consistent
- shared script surface is materially smaller and easier to maintain

## Notes

- This file is intentionally a completed summary, not an append-only historical transcript.
- The active execution log continues in
  `docs/for-agents/current/002-repo-quality-improvement-progress.md`.
