# Remove Bidirectional Plan

## Goal

Remove `den._.bidirectional` from the tracked repo without collapsing the Home Manager surface that currently depends on host-to-user routing, while keeping `predator` and `aurelius` builds green throughout the migration.

## Scope

In scope:
- diagnose why removing `den._.bidirectional` drops most of the Home Manager output
- migrate tracked host-owned Home Manager config to the current upstream mutual-provider model
- keep host-only NixOS config and user-owned NixOS config working during the transition
- validate `predator` and `aurelius` after each meaningful slice
- update active repo docs that still teach `bidirectional`

Out of scope:
- upstream `den` changes
- private override files under `private/`
- unrelated refactors in host composition files
- aesthetic cleanup unrelated to the bidirectional removal

## Current State

- The repo is pinned to `den` revision `66fba2024976e8824daf4e978c2259aabc22e360` in [flake.lock](/home/higorprado/nixos/flake.lock).
- The local checkout at `/home/higorprado/git/den` is already at `66fba20`; no pull is currently needed to inspect the upstream change.
- Upstream removed `den._.bidirectional` in `54ad092` (`feat(batteries): remove bidirectional (#308)`).
- Upstream tests now treat host-owned `homeManager` config as ignored unless mutual routing is enabled through `den._.mutual-provider` and the host contributes via `provides.<user>` or `provides.to-users`.
- The tracked repo still includes `den._.bidirectional` in [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix).
- The tracked repo already includes `den._.mutual-provider` in that same user aspect and already uses explicit user-to-host routing through `provides.predator`.
- The reason removing `den._.bidirectional` appears to remove almost the entire Home Manager closure is that many host-owned aspects included by `predator` still emit top-level `homeManager` config instead of mutual host-to-user config.
- A repo-wide search shows host-owned Home Manager emission in many tracked files, including:
- [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
- [modules/features/system/docker.nix](/home/higorprado/nixos/modules/features/system/docker.nix)
- [modules/features/system/ssh.nix](/home/higorprado/nixos/modules/features/system/ssh.nix)
- [modules/features/shell/fish.nix](/home/higorprado/nixos/modules/features/shell/fish.nix)
- [modules/features/dev/editor-neovim.nix](/home/higorprado/nixos/modules/features/dev/editor-neovim.nix)
- [modules/features/dev/editor-emacs.nix](/home/higorprado/nixos/modules/features/dev/editor-emacs.nix)
- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)
- [modules/features/desktop/niri.nix](/home/higorprado/nixos/modules/features/desktop/niri.nix)
- [modules/features/desktop/desktop-apps.nix](/home/higorprado/nixos/modules/features/desktop/desktop-apps.nix)
- [modules/features/desktop/dms-wallpaper.nix](/home/higorprado/nixos/modules/features/desktop/dms-wallpaper.nix)
- [modules/features/desktop/music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
- plus many other host-owned feature files under `modules/features/` that currently emit `homeManager = ...`
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) already uses explicit host-to-user routing for `provides.higorprado`, which is the right direction under the current `den`.

## Desired End State

- `den._.bidirectional` is removed from [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix).
- The repo keeps `den._.mutual-provider` as the only tracked host<->user routing battery.
- Host-owned Home Manager behavior that should reach all users is expressed through `provides.to-users.homeManager` or equivalent mutual-provider patterns.
- Host-owned Home Manager behavior that should reach one specific user is expressed through `provides.<user>.homeManager`.
- User-owned NixOS config that should reach hosts keeps using explicit user-to-host routing, such as `provides.predator`.
- `predator` and `aurelius` validate successfully without a large unintended drop in Home Manager closure contents.
- Active docs no longer instruct tracked users to rely on `bidirectional`.

## Phases

### Phase 0: Baseline And Inventory

Targets:
- confirm the current bidirectional dependency surface before changing code
- identify the highest-value migration slices instead of changing every feature at once

Changes:
- no functional code changes
- record the files included by `predator` and `aurelius` that still emit top-level host-owned `homeManager`
- record the current Home Manager and system build baselines for `predator`

Validation:
- `nix flake metadata`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- optional baseline capture for closure comparison:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path.drvPath`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- none; baseline and inventory only

Commit target:
- none

### Phase 1: Migrate Host-Specific Mutual Routing First

Targets:
- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)

Changes:
- keep `den._.mutual-provider`
- remove `den._.bidirectional`
- preserve the current user-to-host route `provides.predator`
- confirm that host-to-user config that is already explicit, such as `provides.higorprado`, still behaves as intended without bidirectional
- do not yet migrate all generic feature-level Home Manager config; this phase isolates the pair-routing mechanics first

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`

Diff expectation:
- host/user pair routing should remain intact
- generic host-owned Home Manager config is expected to be incomplete until later phases

Commit target:
- `refactor(den): drop bidirectional from explicit pair routing`

### Phase 2: Migrate Generic Host-Owned Home Manager Features

Targets:
- the host-owned aspects included by `predator` and `aurelius` that currently emit top-level `homeManager`

Changes:
- convert generic host-owned Home Manager config from:
- `homeManager = { ... }: { ... };`
- or host-owned parametric HM emission
- into:
- `provides.to-users.homeManager = ...`
- or `provides.to-users = { user, ... }: { homeManager = ...; }`
- keep the narrowest correct context:
- no host/user context when static config is enough
- `{ user }` only when the per-user data is genuinely needed
- preserve plain host-owned `nixos` config as-is; only the HM routing path should move

Suggested slice order:
- first, broad generic HM packages/settings that account for most of the lost closure:
- shell/editor/tooling features under `modules/features/shell/` and `modules/features/dev/`
- second, desktop/user-environment features under `modules/features/desktop/` and `modules/desktops/`
- third, any remaining host-owned HM from system features that intentionally shape the user environment

Validation after each slice:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh predator`

Diff expectation:
- each slice should restore a concrete portion of the Home Manager surface without changing unrelated system behavior

Commit target:
- `refactor(home): route host-owned hm config through mutual-provider`

### Phase 3: Compare Closures And Catch Silent Regressions

Targets:
- validation only

Changes:
- no further code changes unless the diff shows a missing feature

Validation:
- compare pre/post closures for the Home Manager path and system toplevel
- `nix store diff-closures <before-hm> <after-hm>` or `nix run nixpkgs#nvd -- diff <before> <after>` if needed
- `./scripts/run-validation-gates.sh all`

Diff expectation:
- no large unexplained loss of user packages or desktop/runtime integrations
- any remaining loss must be traceable to a specific feature not yet migrated

Commit target:
- none if the migration slices are sufficient

### Phase 4: Docs And Cleanup

Targets:
- [docs/for-agents/002-den-architecture.md](/home/higorprado/nixos/docs/for-agents/002-den-architecture.md)
- [docs/for-agents/006-extensibility.md](/home/higorprado/nixos/docs/for-agents/006-extensibility.md)
- [docs/for-agents/999-lessons-learned.md](/home/higorprado/nixos/docs/for-agents/999-lessons-learned.md)

Changes:
- remove or rewrite tracked repo guidance that still recommends `bidirectional`
- document the repo’s chosen host-to-user mutual pattern with `provides.to-users` / `provides.<user>`

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- docs match the new tracked routing model

Commit target:
- `docs(den): replace bidirectional guidance with mutual routing`

## Risks

- the migration surface is broad; changing all host-owned Home Manager features in one pass would be high-risk and hard to review
- top-level host `homeManager` in tracked features may currently look valid but silently do nothing once `bidirectional` is removed
- some features may need per-user routing rather than `to-users`, especially where current config uses `user` data implicitly
- closure comparisons are important because successful evaluation alone may still hide large loss of packages or runtime integration

## Definition of Done

- `den._.bidirectional` no longer appears in tracked code
- explicit mutual-provider routing is the only tracked host<->user routing path
- host-owned Home Manager features that should reach users do so through `provides.to-users` or `provides.<user>`
- `predator` Home Manager and system builds pass without the large package drop observed when removing `bidirectional` today
- `./scripts/run-validation-gates.sh all` passes
- tracked docs reflect the new model
