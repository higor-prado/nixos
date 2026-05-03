# Optimization & Organization Report — 2026-05-02

Repo audit focusing on simplification, deduplication, and organization opportunities.
No functional changes; everything currently evaluates and builds correctly.

**Scope**: `modules/`, `hardware/`, `scripts/`, `lib/`, `config/`, `pkgs/`, `flake.nix`
**Stats**: 78 feature modules, 1 desktop composition, 3 hosts — 4,577 LOC Nix + 2,726 LOC shell

---

## 1. 🔴 Shared Infrastructure Block — extract `base-infra.nix`

**What**: All 3 hosts duplicate these 5 imports identically:

```nix
inputs.home-manager.nixosModules.home-manager
nixos.system-base
nixos.home-manager-settings
nixos.nixpkgs-settings
nixos.nix-settings
```

**Severity**: Medium. Pattern is intentional per architecture doc ("explicitness"), but 15 lines × 3 = 45 duplicated lines that will never diverge for this repo's scale.

**Proposal**: Create `modules/features/core/_base-infra.nix` (underscore-prefixed, auto-import skipped):

```nix
{ inputs, ... }:
{
  flake.modules.nixos.base-infra = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      (import ../features/core/system-base.nix).flake.modules.nixos.system-base
      # ... etc
    ];
  };
}
```

Then hosts import `nixos.base-infra` once. Eliminates 30 duplicated lines across hosts.

**Trade-off**: Slight loss of explicit visibility. Since all hosts will always need these 5, the trade-off is net positive for this repo size.

---

## 2. 🔴 Fish Abbreviations Dominate Host Files

**What**: Fish abbreviations consume 25-29% of host file content:

- `aurelius.nix`: ~29% of 98 lines
- `cerebelo.nix`: ~26% of 99 lines
- `predator.nix`: also heavy (operatorFishAbbrs takes ~55 lines + remote abbreviations)

**Severity**: Medium-High. These are purely cosmetic operator shortcuts, not architecture. They make host files hard to scan for structure.

**Proposal A (lightweight)**: Move abbreviations into `_`-prefixed files next to each host:

```
modules/hosts/_predator-fish-abbrs.nix
modules/hosts/_aurelius-fish-abbrs.nix
modules/hosts/_cerebelo-fish-abbrs.nix
```

Each would be a simple attrset. Host files would do:

```nix
programs.fish.shellAbbrs = import ./_predator-fish-abbrs.nix;
```

**Proposal B (more aggressive)**: Move to feature module `modules/features/shell/_host-fish-abbrs.nix` with per-host attrsets, import the right one per host via `config.networking.hostName`.

**Recommendation**: Proposal A. Keeps host ownership clear, removes visual noise, trivial to implement.

---

## 3. 🟡 xdg.portal Config Duplication in hyprland-standalone.nix

**What**: `hyprland-standalone.nix` defines identical `xdg.portal` config in both the NixOS and Home Manager blocks. The comment explains HM controls `NIX_XDG_DESKTOP_PORTAL_DIR`, but the portal `default` and `config` blocks are duplicated line-for-line:

```nix
# NixOS block (line ~16)
xdg.portal = {
  enable = true;
  extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
  config.hyprland = {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
};

# HM block (line ~38) — identical except mkDefault vs direct
xdg.portal = {
  enable = true;
  extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  config.hyprland = {
    default = [ "hyprland" "gtk" ];
    "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  };
};
```

**Severity**: Low-Medium. If portal defaults ever change, both blocks must be updated.

**Proposal**: Extract a shared `_desktop-portal-config.nix` let-binding or underscore file that both blocks reference. The `enable` and `extraPortals` differ but `config.hyprland` is identical.

---

## 4. 🟡 mutableCopy Verbosity — Template Abstraction

**What**: `waybar.nix` has 7 near-identical `mutableCopy.mkCopyOnce` calls, `walker.nix` has 7, `hyprland-standalone.nix` has 9 `provisionHyprlandLuaFile` + 1 manual copy.

**Severity**: Low. Purely cosmetic, each entry is intentionally explicit (per architecture doc lessons). Still, reading intent through the noise is harder than it could be.

**Proposal (optional)**: Add a helper in `lib/mutable-copy.nix`:

```nix
mkCopyOnceBatch = targetBase: files: lib.concatStringsSep "\n" (
  lib.mapAttrsToList (target: source:
    mkCopyOnce { source; target = "${targetBase}/${target}"; }
  ) files
);
```

Then `waybar.nix` becomes:

```nix
home.activation.provisionWaybarScripts = lib.hm.dag.entryAfter [ "writeBoundary" ] (
  mutableCopy.mkCopyOnceBatch "$HOME/.config/waybar/scripts" {
    "mako.sh" = ../../../config/apps/waybar/scripts/mako.sh;
    "mako-dnd.sh" = ../../../config/apps/waybar/scripts/mako-dnd.sh;
    # ...
  }
);
```

**Trade-off**: Less explicit, but more scannable. The `hyprland-standalone.nix` already has `provisionHyprlandLuaFile` showing this pattern works.

---

## 5. 🟢 aurelius Boot Config Inconsistency

**What**: `hardware/aurelius/default.nix` has `boot.loader` config inline, while `predator` has it in a separate `boot.nix` file and `cerebelo` has it in `board.nix`.

**Severity**: Very Low. No functional issue; just structural inconsistency.

**Proposal**: Move aurelius boot config to `hardware/aurelius/boot.nix` for consistency. Already fits the predator pattern.

---

## 6. 🟢 Core Module Granularity — `nixpkgs-settings.nix` is Tiny

**What**: `modules/features/core/nixpkgs-settings.nix` (12 lines) only sets `allowUnfree = true`. Same with `nix-cache-settings.nix` (just substituters).

**Severity**: Very Low. These were likely split for future growth. If they stay this small indefinitely, merging them into a single `core/policy.nix` would reduce file count.

**Proposal (defer)**: No action needed. Wait to see if they grow. Current granularity is fine.

---

## 7. 🟢 Flake Input Hygiene — All Inputs Used

**What**: `check-flake-inputs-used.sh` confirms all declared flake inputs have references:

- `spicetify-nix` → `modules/features/desktop/music-client.nix` ✓
- `catppuccin-zen-browser-src` → `pkgs/default.nix` ✓
- `waypaper-src` → `modules/features/desktop/waypaper.nix` ✓
- All others confirmed wired.

**Status**: ✅ Clean. No dead inputs.

---

## 8. 🟢 Dendritic Discipline — Zero `mkIf` Usage

**What**: `mkIf` is completely absent from all tracked module files — the repo follows the "feature inclusion IS the condition" rule perfectly.

**Status**: ✅ Excellent. Gold standard.

---

## 9. 🟢 Private Import Consistency

**What**: All 3 hardware defaults (`predator`, `aurelius`, `cerebelo`) use the same pattern:

```nix
++ lib.optional (builtins.pathExists ...) .../private/hosts/<name>/default.nix;
```

**Status**: ✅ Consistent. No drift.

---

## 10. 🟡 Host File Size & Structure

**What**: `predator.nix` is 189 lines — the largest module in the repo. Its structure:

- 55 lines: `operatorFishAbbrs` (abbreviations)
- 55 lines: block definitions (`nixosInfrastructure`, `nixosCoreServices`, etc.)
- 79 lines: everything else (function, wiring, hm block)

`aurelius.nix` (98 lines) and `cerebelo.nix` (99 lines) are more proportionate.

**Severity**: Low. predator is the most complex host (desktop + gaming + all dev tools).

**Proposal**: If abbreviations are extracted (item 2), predator drops to ~134 lines — much more manageable.

---

## 11. 🟢 Script Inventory — Clean Separation

**What**: 9 tracked scripts exist outside the gate runner. Per validation docs (005), these are intentionally classified as `shared-aux`, not gate scripts:

- `audit-system-up-to-date.sh` — audit/report
- `check-changed-files-quality.sh` — targeted refactor helper
- `check-runtime-smoke.sh` — local desktop session check
- `check-sd-boot.sh` — cerebelo one-shot
- `fix-cerebelo-nvme.sh` — cerebelo one-shot
- `flash-cerebelo-sd.sh` — cerebelo one-shot
- `new-host-skeleton.sh` — host generator
- `report-maintainability-kpis.sh` — KPI helper
- `report-persistence-candidates.sh` — diagnostic helper

**Status**: ✅ Documented and intentional.

---

## 12. 🟢 Docs Discipline

**What**: `check-docs-drift.sh` passes. No dead references in living docs.

**Status**: ✅ Clean.

---

## Summary — Prioritized Action Items

| #   | Item                                 | Impact  | Effort | Recommendation                                  |
| --- | ------------------------------------ | ------- | ------ | ----------------------------------------------- |
| 1   | Extract shared `base-infra` module   | Medium  | 15 min | Do it — 30 duplicated lines across 3 hosts      |
| 2   | Move fish abbreviations to `_`-files | High    | 20 min | **Highest ROI** — host files shrink 25-29%      |
| 3   | xdg.portal in hyprland-standalone    | N/A     | —      | ✅ False alarm — two config layers, both needed |
| 4   | `mkCopyOnceBatch` helper             | Low     | 10 min | Cosmetic, worth doing with item 2               |
| 5   | Move aurelius boot to `boot.nix`     | Trivial | 5 min  | ✅ Done                                         |
| 6   | Merge tiny core modules              | Trivial | 5 min  | Defer; may grow                                 |

### Estimated total effort: ~1 hour

### Risk level: Near zero — all changes are structural reorganization, no behavior changes

---

## Things NOT to Change (Intentional Design)

1. **Host import explicitness** — Architecture doc explicitly requires concrete host composition. Don't abstract import blocks beyond shared infrastructure.

2. **Desktop composition duplication** — Single composition file (`hyprland-standalone.nix`) is correct for this repo. No abstraction needed.

3. **`_module.args` on cerebelo** — Required by upstream `nixos-rk3588` board modules. Documented as narrow compatibility bridge, not a pattern to spread.

4. **`optionalAttrs` in templates.nix** — Single correct usage. No issue.

5. **Catppuccin catalog pattern** — `_theme-catalog.nix` + `_papirus-tray-patched.nix` is a well-structured shared constant pattern. Don't touch.

---

## File-Level LOC Summary

```
Top 10 largest files:
  189  modules/hosts/predator.nix
  166  modules/features/desktop/walker.nix
  121  modules/features/dev/editors-neovim.nix
  111  modules/features/dev/devenv.nix
  107  modules/desktops/hyprland-standalone.nix
   99  modules/hosts/cerebelo.nix
   98  modules/hosts/aurelius.nix
   84  modules/features/shell/fish.nix
   77  modules/features/desktop/mime-defaults.nix
   76  modules/features/desktop/waybar.nix

Size distribution (feature + desktop + host):
  1-10  lines:   4 files
  11-20 lines:  26 files
  21-40 lines:  24 files
  41-80 lines:  23 files
  81+   lines:   8 files
```
