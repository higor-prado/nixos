# Repo Audit Report — 2026-04-11

Deep audit of the tracked repo surface: flake inputs, feature modules, host
compositions, hardware files, config payloads, scripts, tests, and docs.

---

## Summary

| Severity | Count |
|----------|-------|
| High     | 0     |
| Medium   | 7     |
| Low      | 5     |

No build-breaking issues or architectural violations found. The dendritic
pattern is consistent. All published modules are consumed by at least one host.
All flake inputs are used. The issues below are drift, stale docs, and minor
cosmetic concerns.

---

## Medium Findings

### M1. Stale feature count in two docs

**Files:**
- `docs/for-agents/001-repo-map.md` line 8: says `71+`
- `docs/for-humans/02-structure.md` line 4: says `53+`

**Actual:** 72 feature `.nix` files under `modules/features/` (excluding
underscore-prefixed data files).

Both numbers are wrong. The for-agents doc is close; the for-humans doc is
significantly off.

---

### M2. for-humans multi-host doc missing cerebelo

**File:** `docs/for-humans/03-multi-host.md` line 27

Says "predator and aurelius are the only tracked live hosts." Cerebelo has
existed since at least 2026-03-28 with a full host file, hardware directory,
and active plan history. The doc needs a cerebelo section.

---

### M3. Flake description is host-specific

**File:** `flake.nix` line 2

```
description = "NixOS Config - Predator";
```

The repo now has three hosts. The description should reflect that this is a
multi-host config, not predator-specific.

---

### M4. Cyberpunk-specific window rule lives in the shared desktop config

**File:** `config/desktops/dms-on-niri/custom.kdl` lines ~250-256

```
window-rule {
    match title=r#"Cyberpunk 2077"#
    open-focused true
    geometry-corner-radius 0
    clip-to-geometry false
}
```

Plan 075 explicitly decided that per-game fixes should stay opt-in and not
define the baseline gaming stack. This window rule is a Cyberpunk-specific
workaround that survived the gaming cleanup. It lives in the shared dms-on-niri
composition config that gets provisioned to any host using that desktop.

Low risk today (only predator uses dms-on-niri), but it violates the stated
principle and will be confusing if a second host ever adopts the same desktop
composition.

---

### M5. Hardcoded monitor output config in shared desktop config

**File:** `config/desktops/dms-on-niri/custom.kdl` lines 9-19

```
output "eDP-1"  { mode "1920x1200@165.001"; scale 1; ... }
output "HDMI-A-1" { mode "3840x2160@143.988"; scale 1.5; ... }
```

These are predator's physical outputs hardcoded in the shared dms-on-niri
desktop composition. Same concern as M4: only predator uses this today, but
the config is structured as a reusable composition. If a second host with
different monitors adopts dms-on-niri, this will be wrong.

---

### M6. impermanence follows empty strings instead of nixpkgs

**File:** `flake.nix` lines 17-19

```nix
impermanence = {
  url = "github:nix-community/impermanence";
  inputs.nixpkgs.follows = "";
  inputs.home-manager.follows = "";
};
```

Empty `follows = ""` is an unusual pattern. The common patterns are either:
- Omit `follows` entirely (use the input's own lock)
- Set `follows = "nixpkgs"` (use the repo's nixpkgs)

Empty strings may work by accident (they effectively mean "follow nothing"),
but they're non-obvious and fragile across nix versions. The intent should be
documented, or the follows lines should be removed to let impermanence use its
own dependency closure.

---

### M7. Mutable-copy helper imported four times with relative path repetition

**Files:**
- `modules/desktops/dms-on-niri.nix` line 22
- `modules/desktops/niri-standalone.nix` line 26
- `modules/features/desktop/dms-wallpaper.nix` line 6
- `modules/features/desktop/niri.nix` line 37

Each file does:
```nix
mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
```
(or `../../../lib/` from features).

This works, but the same import-with-relative-path is repeated four times.
If the helper ever gains a parameter, all four call sites must be updated in
lockstep. This is a DRY@2 candidate — the repo's own lessons say "when you
write the same pattern a second time, stop and extract."

Severity is medium only because the helper is stable; it's low urgency but
worth noting.

---

## Low Findings

### L1. `htoprc` is provisioned but btop is the primary tool

**File:** `modules/features/shell/monitoring-tools.nix`

Provisions `config/apps/htop/htoprc` via `xdg.configFile`. The repo map
describes monitoring-tools.nix as "htop, btop, bottom, fastfetch." If btop is
the primary tool and htop is secondary, this is fine. If htop is no longer
used interactively, the config payload is dead weight.

---

### L2. `config/apps/logid/logid.cfg` is hardware-owned, not module-owned

**File:** `hardware/predator/hardware/peripherals-logi.nix`

The logid config is read via `builtins.readFile ../../../config/apps/logid/logid.cfg`.
This is a hardware file reaching into the shared `config/` tree with a deep
relative path. It works, but it's an unusual boundary: `config/` is generally
consumed by `modules/`, not `hardware/`. No action required, just an awareness
note.

---

### L3. `niri-standalone` desktop composition is a placeholder

**File:** `config/desktops/niri-standalone/custom.kdl`

Contains only a comment: "This file is intentionally minimal so the base Niri
config stays reusable." No host currently imports this composition. It's not
dead code (it's a valid empty overlay), but it's also not earning its keep
until a second desktop composition actually uses it.

---

### L4. Predator-specific fish abbreviations in host file are dense

**File:** `modules/hosts/predator.nix` lines 24-52

Contains ~15 fish abbreviations specific to the predator operator. This is
architecturally correct (host-operator commands belong in the host file per
lesson 33). But the density makes the host file harder to scan. If the list
grows, consider extracting into an adjacent underscore file like
`modules/hosts/_predator-abbreviations.nix`.

No action required now — just a scalability note.

---

### L5. `linuwu_sense` group name is a system group, not a hardcoded username

**File:** `hardware/predator/hardware/laptop-acer.nix` line 55

```nix
users.groups.linuwu_sense = { };
```

This was flagged by one audit agent as a hardcoded username. It's not — it's a
system group for the kernel module's device permissions. The naming follows the
upstream project convention. No issue.

---

## What Is Clean

- **All published modules are consumed.** Every `flake.modules.nixos.*` and
  `flake.modules.homeManager.*` published by feature files is imported by at
  least one host composition. No orphan features.

- **All flake inputs are used.** Every input in `flake.nix` is consumed by at
  least one module or package derivation. No dead inputs.

- **No architectural violations.** No `specialArgs`, no synthetic `mkIf`
  enable flags, no options declared outside their owners, no software policy
  in hardware files, no hardcoded usernames in tracked runtime.

- **Script registry is accurate.** `tests/pyramid/shared-script-registry.tsv`
  lists all 26 scripts, and every listed script exists on disk. No unlisted
  scripts exist in `scripts/`.

- **Lib helpers are used.** `_helpers.nix` (portalExecPath, portalPathOverrides)
  is consumed by 3 modules. `mutable-copy.nix` is consumed by 4 modules.

- **Config payloads are referenced.** All files under `config/apps/` and
  `config/desktops/` are referenced by at least one tracked module.

- **Host compositions are consistent.** All three hosts (predator, aurelius,
  cerebelo) compose their imports correctly from published feature and desktop
  modules.

- **The dendritic pattern holds.** Auto-import via import-tree, published
  module surface, explicit host wiring — all consistent.
