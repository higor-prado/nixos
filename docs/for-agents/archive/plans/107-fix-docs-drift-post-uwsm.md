# Fix Documentation Drift After UWSM Migration

## Goal

Audit all living docs against current repo state, fix stale descriptions,
and add UWSM-related documentation.

## Findings

### 1. `001-repo-map.md` — hyprland.nix description stale

**Current:** "Hyprland Wayland compositor without automatic idle lock/DPMS"  
**Reality:** Now uses UWSM for session management. Should mention UWSM.

### 2. `001-repo-map.md` — greetd.nix missing UWSM context

**Current:** "greetd display manager with tuigreet terminal greeter"  
**Reality:** Should mention it launches Hyprland via `uwsm start`.

### 3. `001-repo-map.md` — missing hardware/aurelius section

Predator and cerebelo have hardware sections. Aurelius doesn't.

### 4. `001-repo-map.md` — no UWSM documentation anywhere

No mention of `programs.uwsm`, `withUWSM`, or how session management works.

### 5. `003-module-ownership.md` — hyprland.nix split ownership wrong

**Current:** "HM owns session bootstrap and user config materialization"  
**Reality:** HM only owns `wayland.windowManager.hyprland`. Session bootstrap is UWSM.

### 6. `001-repo-map.md` — underscrore files section

References `regreet.nix` as a user of `_theme-catalog.nix` — regreet was removed.

### 7. `999-lessons-learned.md` — clean

No drift found.

## Scope

In scope:
- Fix all 6 findings above
- Add UWSM mentions where architecturally relevant
- Document session management flow

Out of scope:
- Archive docs (already frozen)
- Creating new docs files
- Changing any module code

## Phases

### Phase 1: Fix 001-repo-map.md

Changes:
- `hyprland.nix`: update to mention UWSM
- `greetd.nix`: add UWSM launch context  
- Add `hardware/aurelius/` section (similar to cerebelo)
- Fix `_theme-catalog.nix`: remove regreet reference
- Add UWSM note to Desktop section preamble

### Phase 2: Fix 003-module-ownership.md

- `hyprland.nix` split ownership: "HM owns session bootstrap" → "HM owns compositor user config only; session bootstrap is UWSM"

### Phase 3: Add UWSM reference to 002-architecture.md or repo-map

Mention in desktop module descriptions that UWSM manages the compositor session
via `programs.hyprland.withUWSM` + `programs.uwsm.waylandCompositors`.

Validation:
- `./scripts/run-validation-gates.sh structure` (docs-drift check)

Commit target:
- `docs: fix drift after UWSM migration, add aurelius hardware section`
