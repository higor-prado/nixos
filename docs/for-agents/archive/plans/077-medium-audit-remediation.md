# Medium Audit Findings Remediation Plan

## Goal

Address all 7 medium findings from audit report 077 with zero regressions.

## Scope

In scope:
- M1: stale feature counts in docs
- M2: missing cerebelo in multi-host doc
- M3: host-specific flake description
- M4: Cyberpunk window rule in shared desktop config
- M5: hardcoded monitor outputs in shared desktop config
- M6: impermanence empty follows strings
- M7: mutable-copy import repetition

Out of scope:
- low findings (L1-L5)
- any runtime behavioral changes
- any module architecture changes

## Current State

- 72 feature modules under `modules/features/`
- 3 tracked hosts: predator, aurelius, cerebelo
- docs/for-agents/001-repo-map.md claims `71+`
- docs/for-humans/02-structure.md claims `53+`
- docs/for-humans/03-multi-host.md lists only predator and aurelius
- flake.nix description says "NixOS Config - Predator"
- config/desktops/dms-on-niri/custom.kdl has Cyberpunk window rule + predator monitor outputs
- impermanence input has `inputs.nixpkgs.follows = ""` and `inputs.home-manager.follows = ""`
- mutable-copy.nix imported 4 times with relative path boilerplate

## Desired End State

- All docs reflect actual counts and hosts
- Flake description reflects multi-host reality
- Shared desktop config template has no per-game or per-hardware rules
- impermanence follows removed (let it use its own deps) with intent documented
- mutable-copy repetition accepted with documented justification

## Phases

### Phase 1: Doc-only fixes (M1, M2, M3)

Zero regression risk. No code changes. Pure documentation.

Targets:
- `docs/for-agents/001-repo-map.md` line 8
- `docs/for-humans/02-structure.md` line 4
- `docs/for-humans/03-multi-host.md` lines 27-39
- `flake.nix` line 2

Changes:

**M1 — fix feature count:**
- `001-repo-map.md`: change `71+` to `72`
- `02-structure.md`: change `53+` to `72`

**M2 — add cerebelo to multi-host doc:**
- Update "Current tracked hosts" line to list all three hosts
- Add cerebelo section after aurelius:
  ```
  ## cerebelo

  Orange Pi 5 (RK3588S), headless server. Booted from NVMe via extlinux.
  Uses the nixos-rk3588 upstream board stack. Deployed from predator via `nh`.
  ```

**M3 — fix flake description:**
- Change `description = "NixOS Config - Predator";` to
  `description = "NixOS multi-host configuration";`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix flake metadata` (description change is cosmetic but verify metadata still resolves)

Diff expectation:
- no closure changes; docs and flake metadata only

Commit target:
- `docs: fix feature counts, add cerebelo, update flake description`

---

### Phase 2: Desktop config locality (M4, M5)

Low regression risk. The file is a mutable copy-once template. Changes to the
tracked template only affect new provisions (when `~/.config/niri/custom.kdl`
does not already exist on the target host). Existing runtime configs are
untouched because `mkCopyOnce` skips if the target exists.

Targets:
- `config/desktops/dms-on-niri/custom.kdl`

Changes:

**M4 — remove Cyberpunk window rule:**
- Remove lines 250-256 (the `window-rule` block matching `Cyberpunk 2077`)
- Rationale: plan 075 explicitly decided per-game fixes stay opt-in. This rule
  was a Cyberpunk-specific workaround that survived the gaming cleanup. If the
  user needs it, it belongs in their local mutable `custom.kdl`, not in the
  tracked template that every host using dms-on-niri would receive.

**M5 — add awareness comment to monitor output block:**
- Do NOT remove the output config. Only predator uses dms-on-niri today, and
  removing it would break the default template for predator's own first
  provision. Instead, add a comment above the output block:
  ```
  // Monitor outputs below are predator-specific defaults.
  // Adjust for other hardware; this template is only provisioned once
  // (mutable-copy-once pattern).
  ```
- Rationale: the output block is harmless — it's a sensible default for the
  only consumer. A comment makes the locality explicit without breaking the
  working template.

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- Verify the build still provisions `custom.kdl` from the same source path

Diff expectation:
- no closure change; only the text content of the mutable-copy-once template changes
- existing deployed predator config is unaffected (mkCopyOnce does not overwrite)

Rollback:
- `git revert HEAD` restores the Cyberpunk rule and removes the comment

Commit target:
- `refactor(desktop): remove cyberpunk rule from shared template, document monitor locality`

---

### Phase 3: impermanence follows cleanup (M6)

Low regression risk. Removing `follows = ""` and letting impermanence use its
own dependency closure should produce equivalent behavior. The empty-string
follows is a non-obvious way to say "don't follow"; simply omitting the
follows lines expresses the same intent more clearly.

Targets:
- `flake.nix` lines 17-20

Changes:

Current:
```nix
impermanence = {
  url = "github:nix-community/impermanence";
  inputs.nixpkgs.follows = "";
  inputs.home-manager.follows = "";
};
```

New:
```nix
# impermanence uses its own nixpkgs/home-manager; no follows.
impermanence = {
  url = "github:nix-community/impermanence";
};
```

Validation:
- `nix flake lock --update-input impermanence` — regenerate lock entry
- `nix flake metadata` — verify metadata resolves
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath` — verify predator eval unchanged
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath` — verify aurelius eval unchanged
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` — verify build
- `./scripts/run-validation-gates.sh structure`
- Compare drvPath outputs before and after: must be identical

Diff expectation:
- `flake.lock` may update the impermanence node's dependency representation
- All drvPaths must remain identical (proves no behavioral change)
- If drvPaths change, revert immediately and document why empty follows was needed

Rollback:
- `git revert HEAD` + `nix flake lock --update-input impermanence`

Commit target:
- `refactor(flake): simplify impermanence input, remove empty follows`

---

### Phase 4: Accept M7 as documented, not refactored

M7 flags that `mutable-copy.nix` is imported 4 times with the same boilerplate.
After analysis, this is accepted as-is because:

1. The import is a single line per site: `import <path>/mutable-copy.nix { inherit lib; }`
2. The relative paths differ (`../../lib/` vs `../../../lib/`) — no shared path
3. The API is `lib -> { mkCopyOnce }` — maximally stable, no realistic parameter growth
4. DRY solutions all require either:
   - `specialArgs` (forbidden by architecture)
   - a flake-published option (over-engineering for a lib function)
   - `builtins.getFlake` (requires flake in store, not available during eval of local paths)
5. The repo lesson says "DRY at 2" but also "Three similar lines of code is better
   than a premature abstraction." This is 4 single-line imports with no logic —
   the cost of abstracting exceeds the cost of the repetition.

Action: add a brief note in the audit report finding M7 that this was reviewed
and accepted. No code change.

Validation:
- none needed (no change)

Commit target:
- none

---

## Risks

| Phase | Risk | Mitigation |
|-------|------|------------|
| 1 | Doc count drifts again as features are added | Low impact; fix when noticed |
| 2 | User loses Cyberpunk window rule on next provision | mkCopyOnce never overwrites existing file; rule preserved in user's local mutable copy |
| 2 | User wants Cyberpunk rule back | Available in git history; can re-add to local mutable config |
| 3 | flake.lock changes impermanence's dependency resolution | Verified by drvPath comparison before/after; revert if drvPaths differ |
| 3 | impermanence actually needed the empty follows for a reason | drvPath comparison catches any behavioral difference; revert if drvPaths differ |
| 4 | None | No change |

## Definition of Done

- [ ] M1: both docs show `72` feature modules
- [ ] M2: 03-multi-host.md lists all three hosts with descriptions
- [ ] M3: flake.nix description is multi-host
- [ ] M4: custom.kdl has no Cyberpunk window rule
- [ ] M5: custom.kdl monitor outputs have locality comment
- [ ] M6: impermanence follows lines removed, drvPaths identical before/after
- [ ] M7: accepted with documented justification
- [ ] All validation gates pass
- [ ] All three hosts eval and build unchanged (Phase 2-3)
