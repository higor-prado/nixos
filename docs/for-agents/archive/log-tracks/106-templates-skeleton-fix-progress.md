# Templates and Skeleton Fix Progress

## Status

Completed

## Related Plan

- [106-templates-skeleton-fix.md](/home/higorprado/nixos/docs/for-agents/plans/106-templates-skeleton-fix.md)

## Baseline

- Validation gates: PASS
- Fixture test: PASS (both fixtures+templates were equally stale)
- Working tree: clean

## Slices

### Phase 1 — Fix templates

- Desktop template: `nixos.packages-system-tools` → `nixos.server-tools`
- Server template: merged `nixos.packages-server-tools` + `nixos.packages-system-tools` → `nixos.server-tools`
- Commit: `fix(templates): update stale module references in host skeleton templates`

### Phase 2 — Fix skeleton script

- `nixos.packages-fonts` → `nixos.fonts` in `new-host-skeleton.sh`
- Commit: `fix(scripts): update stale module reference in new-host-skeleton`

### Phase 3 — Fix test fixtures

- zeus.nix: `packages-system-tools` → `server-tools`, `packages-fonts` → `fonts`
- ci-runner.nix: merged `packages-server-tools` + `packages-system-tools` → `server-tools`
- Commit: `fix(tests): update fixtures for renamed modules`

### Phase 4 — Whitespace alignment

- Desktop template: `] ++ hardwareImports;` → split across lines (matches auto-formatted fixture)
- Server template: same fix
- Fixture test: PASS
- Commit: `fix(templates): match fixture whitespace for skeleton generator`

### Phase 5 — Final validation

- `./scripts/run-validation-gates.sh structure`: ALL PASS
- `new-host-skeleton-fixture-test.sh`: PASS
- `grep -rn "packages-" templates/ scripts/new-host-skeleton.sh tests/fixtures/new-host-skeleton/`: ZERO
- `./scripts/check-repo-public-safety.sh`: PASS

## Final State

- `new-host-skeleton.sh zeus desktop hyprland-standalone` — generates valid host referencing only existing modules
- `new-host-skeleton.sh ci-runner server` — generates valid server host
- Fixture test validates generated output matches expected
- Zero `packages-` prefix in templates, skeleton script, or fixtures
