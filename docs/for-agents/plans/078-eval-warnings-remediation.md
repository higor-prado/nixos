# Evaluation Warnings Remediation Plan

## Goal

Eliminate all repo-actionable evaluation warnings across all three hosts.

## Current Warnings

| # | Warning | Hosts | Source | Actionable? |
|---|---------|-------|--------|-------------|
| W1 | xorg.libxcb deprecated, renamed to libxcb | predator | `programs.xwayland.enable` in nixpkgs | No — upstream |
| W2 | neovim withRuby default changed true→false | all 3 | `home.stateVersion < "26.05"` + no explicit `withRuby` | Yes |
| W3 | x86_64-darwin last supported in 26.05 | predator | nixpkgs global notice | No — upstream |

## Current State

- `home.stateVersion = "25.11"` (set in `modules/users/higorprado.nix`)
- `system.stateVersion = "25.11"` (set in `modules/features/core/system-base.nix`)
- `programs.neovim` enabled without explicit `withRuby` in `modules/features/dev/editor-neovim.nix`
- No Ruby LSP, Ruby plugins, or Ruby-related packages in the neovim config

## Desired End State

- W1: tracked as upstream; no local fix possible
- W2: silenced by explicit `programs.neovim.withRuby = false;`
- W3: tracked as upstream; no local fix possible
- After W2 fix: aurelius and cerebelo eval clean with zero warnings
- After W2 fix: predator eval has only the two upstream warnings (W1, W3)

## Phases

### Phase 1: Fix neovim withRuby warning (W2)

Targets:
- `modules/features/dev/editor-neovim.nix`

Changes:
- Add `withRuby = false;` to the `programs.neovim` block
- This adopts the new nixpkgs default explicitly
- No behavioral change: the repo's neovim config has no Ruby tooling

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath 2>&1`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath 2>&1`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath 2>&1`
- Verify W2 is gone from all three hosts
- Verify drvPaths are unchanged (proves no behavioral regression)

Diff expectation:
- drvPaths identical; only the warning count changes

Commit target:
- `fix(neovim): adopt new withRuby default explicitly`

---

### Phase 2: Document upstream warnings (W1, W3)

No code change. Record the two remaining warnings in the audit report so they
don't get re-discovered as new issues.

Targets:
- `docs/for-agents/archive/077-repo-audit-report.md`

Changes:
- Add a new section listing the two upstream warnings with justification for
  why they cannot be fixed locally

Validation:
- `./scripts/check-docs-drift.sh`

Commit target:
- `docs(audit): track upstream eval warnings`

## Risks

| Phase | Risk | Mitigation |
|-------|------|------------|
| 1 | withRuby=false breaks a Ruby neovim plugin | No Ruby plugins or LSP exist in the config; nvim config has no Ruby references |
| 1 | drvPath changes | drvPath comparison before/after; revert if they differ |
| 2 | None | Documentation only |

## Definition of Done

- [ ] W2 silenced on all three hosts
- [ ] All three host drvPaths identical to pre-change values
- [ ] W1 and W3 documented as upstream in audit report
- [ ] All validation gates pass
