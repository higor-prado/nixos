# Niri Semantic Package Progress

Date: 2026-03-10
Status: planned

Plan:
- `docs/for-agents/plans/015-niri-semantic-package-plan.md`

## Goal

Move Niri package variant choice out of the feature and into semantic host data.

## Current State

- `modules/features/desktop/niri.nix` currently selects `niri-unstable` directly from `host.inputs.niri.packages.${system}`
- only `modules/hosts/predator.nix` currently includes `niri`
- desktop compositions stay unchanged in this slice

## Notes

- This is the `P1` follow-up identified after the `llm-agents` semantic host selection cleanup.
- The expected end state is `host.desktopPackages.niri` or equivalent semantic host-owned data.
