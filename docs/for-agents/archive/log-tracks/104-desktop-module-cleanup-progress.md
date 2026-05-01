# Desktop Module Cleanup Progress

## Status

Completed

## Related Plan

- [104-desktop-module-cleanup.md](/home/higorprado/nixos/docs/for-agents/plans/104-desktop-module-cleanup.md)

## Baseline

- Validation gates: PASS
- Predator eval: PASS
- Working tree: clean

## Slices

### Phase 1 — Rename packages-fonts.nix → fonts.nix

- `git mv packages-fonts.nix fonts.nix`
- Updated `nixos.packages-fonts` → `nixos.fonts`
- Commit: `refactor(desktop): rename packages-fonts to fonts`

### Phase 2 — Extract browsers into browsers.nix

- Created `browsers.nix` with Firefox, Chromium, Brave, Zen → `homeManager.browsers`
- Rewrote `desktop-apps.nix` with only 4 productivity apps (teams-for-linux, meld, obsidian, super-productivity)
- Simplified `desktop-apps.nix` lambda (no longer needs `inputs`)
- Commit: `refactor(desktop): extract browsers from desktop-apps into browsers module`

### Phase 3 — Update predator imports

- `nixos.packages-fonts` → `nixos.fonts`
- Added `homeManager.browsers` to `hmDesktop`
- Both NixOS + HM eval: PASS
- All 4 browsers + fonts confirmed present in derivation
- Commit: `refactor(predator): update imports for desktop module cleanup`

### Phase 4 — Update docs

- `001-repo-map.md`: `packages-fonts.nix` → `fonts.nix` + added `browsers.nix`
- `003-module-ownership.md`: `packages-fonts.nix` → `fonts.nix`
- Commit: `docs: update repo map and ownership for desktop cleanup`

### Phase 5 — Final validation

- `./scripts/run-validation-gates.sh structure`: ALL PASS
- `./scripts/check-repo-public-safety.sh`: PASS
- `nix build --no-link` predator (NixOS + HM): PASS
- `grep -rn "packages-fonts" modules/ docs/`: CLEAN
- `grep -rn "packages-"` on flake.modules definitions: **ZERO in entire repo**
- `ls modules/features/desktop/`: 25 files (23 active + 2 helpers)

## Final State

### packages- prefix — ELIMINATED from entire repo

```
dev/       → zero (was: packages-toolchains, packages-docs-tools) ✅
system/    → zero (was: packages-server-tools, packages-system-tools) ✅
shell/     → zero (never had) ✅
core/      → zero (never had) ✅
media/     → zero (never had) ✅
desktop/   → zero (was: packages-fonts) ✅  ← LAST ONE
```

### desktop/ directory — 25 files

- `fonts.nix` — renamed from `packages-fonts.nix`
- `browsers.nix` — NEW: Firefox, Chromium, Brave, Zen
- `desktop-apps.nix` — now only productivity apps (was 8 items, now 4)
- All other 20 files unchanged

### Repo-wide consistency achieved

All 6 feature categories now follow flat naming with directory-as-namespace.
Zero `packages-`, `dev-`, or redundant prefixes remain on any `flake.modules` definition.
