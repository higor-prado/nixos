# Templates and Skeleton Fix Plan

## Goal

Fix stale module references in `templates/`, `scripts/new-host-skeleton.sh`, and
`tests/fixtures/new-host-skeleton/` caused by the `system/` and `desktop/` renames.
After this fix, `new-host-skeleton.sh` generates hosts that eval correctly.

## Scope

In scope:

- Update `templates/new-host-skeleton/desktop-module.nix.tpl`: `packages-system-tools` → `server-tools`
- Update `templates/new-host-skeleton/server-module.nix.tpl`: merge `packages-server-tools` + `packages-system-tools` → `server-tools`
- Update `scripts/new-host-skeleton.sh`: `nixos.packages-fonts` → `nixos.fonts`
- Update `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`: `packages-system-tools` → `server-tools`, `packages-fonts` → `fonts`
- Update `tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix`: merge `packages-server-tools` + `packages-system-tools` → `server-tools`
- Verify `new-host-skeleton-fixture-test.sh` passes after fixes

Out of scope:

- Adding new modules to templates (e.g., `editors-neovim`, `monitoring-tools`)
- Changing template structure or placeholder system
- Modifying `new-host-skeleton.sh` logic beyond the stale name fix
- Updating hardware fixture files (they don't reference module names)

## Current State

### Stale references inventory

| File                                     | Stale reference                                               | Correct name         |
| ---------------------------------------- | ------------------------------------------------------------- | -------------------- |
| `templates/.../desktop-module.nix.tpl`   | `nixos.packages-system-tools`                                 | `nixos.server-tools` |
| `templates/.../server-module.nix.tpl`    | `nixos.packages-server-tools` + `nixos.packages-system-tools` | `nixos.server-tools` |
| `scripts/new-host-skeleton.sh` (line 41) | `nixos.packages-fonts`                                        | `nixos.fonts`        |
| `tests/fixtures/.../zeus.nix`            | `nixos.packages-system-tools`                                 | `nixos.server-tools` |
| `tests/fixtures/.../zeus.nix`            | `nixos.packages-fonts`                                        | `nixos.fonts`        |
| `tests/fixtures/.../ci-runner.nix`       | `nixos.packages-server-tools` + `nixos.packages-system-tools` | `nixos.server-tools` |

The `new-host-skeleton-fixture-test.sh` generates hosts from templates using
`new-host-skeleton.sh` and diffs them against the fixtures. Currently the test
would fail because templates reference stale modules.

## Desired End State

- `new-host-skeleton.sh zeus desktop hyprland-standalone` generates a valid host file
  referencing only modules that exist
- `new-host-skeleton-fixture-test.sh` passes (fixtures match generated output)
- Zero `packages-` prefix references in templates, skeleton script, or fixtures

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure` — confirm current state
- Verify `new-host-skeleton-fixture-test.sh` currently FAILS (expected — fixtures are stale)
- `git status` — confirm clean

### Phase 1: Fix templates (.tpl files)

Targets:

- `templates/new-host-skeleton/desktop-module.nix.tpl`
- `templates/new-host-skeleton/server-module.nix.tpl`

Changes (desktop):

```diff
-        nixos.packages-system-tools
+        nixos.server-tools
```

Changes (server):

```diff
-        nixos.packages-server-tools
-        nixos.packages-system-tools
+        nixos.server-tools
```

Validation:

- `grep "packages-" templates/` — must return nothing

Commit target:

- `fix(templates): update stale module references in host skeleton templates`

### Phase 2: Fix skeleton script

Targets:

- `scripts/new-host-skeleton.sh`

Changes:

```diff
-        nixos.packages-fonts
+        nixos.fonts
```

Validation:

- `grep "packages-" scripts/new-host-skeleton.sh` — must return nothing

Commit target:

- `fix(scripts): update stale module reference in new-host-skeleton`

### Phase 3: Fix test fixtures

Targets:

- `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
- `tests/fixtures/new-host-skeleton/server/modules/hosts/ci-runner.nix`

Changes (zeus.nix):

```diff
-        nixos.packages-system-tools
+        nixos.server-tools
-        nixos.packages-fonts
+        nixos.fonts
```

Changes (ci-runner.nix):

```diff
-        nixos.packages-server-tools
-        nixos.packages-system-tools
+        nixos.server-tools
```

Validation:

- `grep "packages-" tests/fixtures/new-host-skeleton/` — must return nothing

Commit target:

- `fix(tests): update fixtures for renamed modules`

### Phase 4: Final validation

Validation:

- `./scripts/run-validation-gates.sh structure` — all gates pass
- `new-host-skeleton-fixture-test.sh` — PASS (generated output matches updated fixtures)
- `grep -rn "packages-" templates/ scripts/new-host-skeleton.sh tests/fixtures/new-host-skeleton/` — must return nothing
- `./scripts/check-repo-public-safety.sh` — PASS

## Risks

- **Fixture test is the canary**: If templates and fixtures are updated correctly,
  the test will pass. If there's a mismatch, the test will catch it.
- **No other scripts reference these templates**: Only `new-host-skeleton.sh`
  consumes the `.tpl` files. Only the fixture test references the fixtures.
- **These are templates, not runtime code**: Changes are purely textual — no
  Nix eval needed for .tpl files. No impact on actual host configs.

## Definition of Done

- [ ] Desktop template: `nixos.packages-system-tools` → `nixos.server-tools`
- [ ] Server template: `packages-server-tools` + `packages-system-tools` → `server-tools`
- [ ] Skeleton script: `nixos.packages-fonts` → `nixos.fonts`
- [ ] Desktop fixture: `packages-system-tools` → `server-tools`, `packages-fonts` → `fonts`
- [ ] Server fixture: merged `packages-*` → `server-tools`
- [ ] `new-host-skeleton-fixture-test.sh` passes
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] Zero `packages-` prefix in templates, skeleton script, or fixtures
