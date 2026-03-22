# Aurelius Close the Loop Progress

## Status

In progress

## Related Plan

- [061-aurelius-close-the-loop.md](/home/higorprado/nixos/docs/for-agents/plans/061-aurelius-close-the-loop.md)

## Baseline

- Active branch: `aurelius-next-steps-plan`
- Working tree has uncommitted clean changes: `predator.nix`, `llm-agents.nix`,
  `flake.lock`, `aurelius.nix`
- Untracked files: `modules/features/system/grafana.nix`,
  `docs/for-agents/plans/060-aurelius-grafana-baseline.md`
- `attic-publisher.nix` on predator runs `attic watch-store` daemon (~500 MB idle)
- All other aurelius phases from original draft are complete per 050 progress log

## Slices

### Slice 1 — Phase 0: baseline commits

- Verified working-tree diffs: `predator.nix` (amdev IPv4 fix), `llm-agents.nix`
  (copilot-cli), `flake.lock` (four input updates) — all dendritic-compliant
- Committed each in a focused commit; held back `aurelius.nix` until grafana.nix
  was tracked
- Gates passed: `./scripts/run-validation-gates.sh structure`
- Evals passed: both `predator` and `aurelius` toplevel drvPaths returned

### Slice 2 — Phase 1: grafana

- `git add`-ed `grafana.nix`, `aurelius.nix`, `060-aurelius-grafana-baseline.md`
- Added `system.activationScripts.grafana-secret-key` to `grafana.nix`: generates
  `/var/lib/grafana/secret-key` on first activation if absent
- Committed in two commits: initial module + activation script fix
- Gates passed: `./scripts/run-validation-gates.sh structure`,
  `./scripts/check-docs-drift.sh`, `./scripts/check-repo-public-safety.sh`
- Deployed: `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- Runtime proof:
  - `grafana.service` is `active (running)` on aurelius
  - `curl http://127.0.0.1:3001/` → HTTP 200 (local)
  - `curl http://aurelius.your-tailnet.ts.net:3001/api/health` → HTTP 200 (from predator)
  - Prometheus datasource provisioned declaratively

### Slice 3 — Phase 2: attic-publisher fix

### Slice 4 — Phase 3: service-owned timers

### Slice 5 — Phase 4: access model

### Slice 6 — Phase 5: exit node

### Slice 7 — Phase 6: reproducibility

### Slice 8 — Phase 7: documentation cleanup

## Final State

- Execution in progress.
