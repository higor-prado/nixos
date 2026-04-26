# Post-Hyprland Drift Remediation Progress

## Status

Completed

## Related Plan

- [079-post-hyprland-drift-remediation.md](/home/higorprado/nixos/docs/for-agents/plans/079-post-hyprland-drift-remediation.md)

## Baseline

- `./scripts/run-validation-gates.sh structure` passed before remediations.
- Drift markers confirmed in living docs (`README.md`, `docs/for-humans/*`, `docs/for-agents/001-repo-map.md`).
- Runtime selection in `modules/hosts/predator.nix` already set to Hyprland standalone composition.

## Slices

### Slice 1 — Agent repo-map alignment

- Updated `docs/for-agents/001-repo-map.md`:
  - removed fragile hardcoded counts in top-level layout
  - expanded `modules/desktops/` table to include:
    - `noctalia-on-niri.nix`
    - `hyprland-standalone.nix`
- Validation:
  - `./scripts/check-docs-drift.sh` ✅
  - `./scripts/check-desktop-composition-matrix.sh` ✅
  - `./scripts/run-validation-gates.sh structure` ✅

### Slice 2 — Human docs + README alignment

- Updated `README.md`:
  - tracked hosts now include `cerebelo`
  - desktop composition example now references Hyprland standalone
  - host model clarifies predator Hyprland + aurelius/cerebelo as server hosts
- Updated `docs/for-humans/00-start-here.md`:
  - predator description changed to Hyprland
  - cerebelo added to host list
- Updated `docs/for-humans/02-structure.md`:
  - removed fragile hardcoded counts
  - refreshed `config/` payload summary for current modules
- Updated `docs/for-humans/03-multi-host.md`:
  - predator now documented as currently Hyprland standalone
- Validation:
  - `./scripts/check-docs-drift.sh` ✅
  - `./scripts/run-validation-gates.sh structure` ✅

### Slice 3 — Plan/note location hygiene

- Moved tracked local notes out of `local/` into canonical agent docs archive surface:
  - `local/PLAN.md` -> `docs/for-agents/archive/log-tracks/078-hyprland-waybar-restart-note.md`
  - `local/HYPRLAND_UWSM_FIX.md` -> `docs/for-agents/archive/log-tracks/079-hyprland-uwsm-session-fix-note.md`
- Note: `docs/for-agents/archive/reports/` cannot receive new tracked files with current `.gitignore` (`reports/` pattern); archive under `archive/log-tracks/` keeps them tracked and discoverable.
- Validation:
  - `./scripts/check-docs-drift.sh` ✅
  - `./scripts/run-validation-gates.sh structure` ✅

### Slice 4 — Final non-regression validation

- Ran full gate suite:
  - `./scripts/run-validation-gates.sh all` ✅

## Final State

- Living docs now match current host/desktop reality (Hyprland on predator, cerebelo included).
- Agent repo map includes current desktop composition surface.
- Tracked local operational notes removed from `local/` and placed in canonical agent docs tree.
- Full validation suite (`all`) passed.
