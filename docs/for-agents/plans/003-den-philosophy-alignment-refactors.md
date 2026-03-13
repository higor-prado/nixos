# Den Philosophy Alignment Refactors

## Goal

Align the remaining tracked Nix modules with den's post-March-13, 2026 context model so host-only concerns are not expressed through wider `{ host, user }` shapes and host NixOS state does not depend on Home Manager user fan-out.

## Scope

In scope:
- refactor tracked feature modules whose context shape is wider than required
- keep behavior unchanged while narrowing ownership/context boundaries
- validate both `predator` and `aurelius` paths after each meaningful slice

Out of scope:
- den upstream changes
- private override files
- unrelated lockfile or editor config churn

## Current State

- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix) was refactored to the new den model and now validates successfully.
- The March 13, 2026 `den` change (`4bdcb63`, `feat(batteries): Opt-in den._.bidirectional`) makes host-to-user OS reentry explicit instead of implicit.
- The repo currently has no tracked use of `den._.bidirectional`.
- Most tracked features already follow the intended pattern: host-only NixOS concerns use `{ host }`, user-owned OS concerns live in user aspects/batteries, and generic HM config lives in `homeManager`.
- Remaining follow-up candidates fall into two groups:
  - one architectural-risk case where host-wide NixOS config is still coupled to `{ host, user }`
  - several cleanup cases where HM-only blocks use `{ host, user }` even though `user` is unused

## Desired End State

- Host-wide NixOS concerns are never gated by HM user context unless that is explicitly intended.
- HM-only config uses the narrowest required context:
  - owned `homeManager` when no host/user data is needed
  - `{ host }` parametric includes when host data is needed
  - `{ host, user }` only when user-specific logic is real
- Repo feature code is easier to reason about against current den tests and docs.

## Phases

### Phase 0: Baseline

Validation:
- confirm current audit findings against the active report
- capture the current candidate files and intended context shape per file

### Phase 1: Decouple Host NixOS State From HM User Context

Targets:
- [modules/features/dev/llm-agents.nix](/home/higorprado/nixos/modules/features/dev/llm-agents.nix)

Changes:
- split host-wide `nixos.environment.systemPackages` from HM user package wiring
- move host-wide system package selection to host-only context
- keep HM package propagation as host-owned `homeManager` or host-only HM config, depending on the final narrowest form
- remove the current `den.lib.parametric.exactly` / `{ host, user }` coupling if no longer justified

Validation:
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- `aurelius` keeps receiving `llmAgents.systemPackages`
- no feature behavior depends on HM user fan-out for host-wide system packages

Commit target:
- `refactor(llm-agents): separate host nixos from hm fan-out`

### Phase 2: Narrow HM-Only Host Contexts

Targets:
- [modules/features/desktop/desktop-apps.nix](/home/higorprado/nixos/modules/features/desktop/desktop-apps.nix)
- [modules/features/desktop/dms-wallpaper.nix](/home/higorprado/nixos/modules/features/desktop/dms-wallpaper.nix)
- [modules/features/desktop/theme-zen.nix](/home/higorprado/nixos/modules/features/desktop/theme-zen.nix)
- [modules/features/desktop/music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
- [modules/features/desktop/theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix)

Changes:
- convert HM-only `{ host, user }` lambdas to `{ host }` where `user` is unused
- convert HM-only blocks to owned `homeManager` where neither `host` nor `user` is needed
- leave host-only `home-manager.sharedModules` registration in host NixOS context

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-config-contracts.sh`

Diff expectation:
- no behavioral changes
- smaller context surfaces and clearer ownership

Commit target:
- `refactor(desktop): narrow hm context shapes`

### Phase 3: Full Repo Validation

Targets:
- repo validation commands only

Changes:
- no further code changes unless validation exposes a follow-up issue

Validation:
- `./scripts/run-validation-gates.sh`
- optional: `./scripts/check-repo-public-safety.sh`

Diff expectation:
- all tracked validations remain green after the alignment refactors

Commit target:
- none if earlier slices are sufficient

## Risks

- some current patterns may be working incidentally and will need careful validation to prove behavior stays unchanged
- `aurelius` is the key host for verifying `llm-agents` system package behavior
- narrowing context shapes can expose hidden assumptions in future multi-user hosts even when single-user hosts appear unchanged

## Definition of Done

- the architectural-risk case in `llm-agents.nix` is removed
- HM-only host config uses the narrowest defensible context in the audited candidate files
- `predator` and `aurelius` validations pass
- the repo’s den usage reads cleanly against the current post-March-13 den philosophy
