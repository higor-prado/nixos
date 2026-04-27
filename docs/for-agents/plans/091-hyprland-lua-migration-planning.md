# Hyprland Lua Migration Planning

## Goal

Produce a migration plan for moving the repo's Hyprland user configuration toward upstream's new Lua-based config model, without performing the migration yet. The plan must account for the current live modular Hyprland runtime on `predator`, the repo's current minimal `user.conf` provisioning model, and upstream's stated deprecation path for legacy hyprlang configs.

## Scope

In scope:
- gather upstream context for Hyprland Lua configs
- inventory current repo-owned and live Hyprland config shapes
- define a safe migration target and staged rollout plan
- identify blockers, unknowns, and validation gates
- decide what repo structure should own future Lua configs

Out of scope:
- performing the actual Hyprland migration now
- changing live Hyprland behavior now
- broad desktop redesign unrelated to the config language transition
- non-Hyprland desktop surfaces already covered by plan 090

## Current State

- Upstream reference repo has been cloned locally to:
  - `~/git/Hyprland`
- Clone state at planning time:
  - repository: `https://github.com/hyprwm/Hyprland.git`
  - current checked-out revision: `5419ea6a`
- Upstream announcement reviewed:
  - `https://hypr.land/news/26_lua/`
- Key upstream facts from that announcement:
  - starting on `git` / future `0.55`, Hyprland can use `hyprland.lua`
  - if `hyprland.lua` exists, it is loaded instead of legacy `hyprland.conf`
  - the selection is done at startup only
  - legacy hyprlang config support is expected to continue for only `1 - 2` releases after `0.55`
  - new config features will no longer be added to hyprlang
- Current repo-owned Hyprland surface is minimal:
  - `config/desktops/hyprland-standalone/hyprland.conf`
  - provisioned to `~/.config/hypr/user.conf` by `modules/desktops/hyprland-standalone.nix`
- Current live Hyprland runtime on `predator` is modular and substantially richer than the repo stub:
  - `~/.config/hypr/appearance.conf`
  - `~/.config/hypr/binds.conf`
  - `~/.config/hypr/env.conf`
  - `~/.config/hypr/input.conf`
  - `~/.config/hypr/layout.conf`
  - `~/.config/hypr/monitors.conf`
  - `~/.config/hypr/rules.conf`
  - `~/.config/hypr/startup.conf`
  - `~/.config/hypr/user.conf`
  - `~/.config/hypr/scripts/*.sh`
- Therefore there are really two Hyprland gaps to solve later:
  1. repo-vs-live parity for the current modular runtime
  2. hyprlang-to-Lua migration for the eventual upstream change

## Desired End State

- We have a clear, staged, repo-specific migration plan for Lua-based Hyprland configs.
- The plan chooses an explicit future repo ownership model for Hyprland configs.
- The plan separates parity sync from syntax migration so we do not entangle two risky changes blindly.
- Validation and rollback expectations are defined before any migration starts.

## Phases

### Phase 0: Upstream capability and docs inventory

Targets:
- `~/git/Hyprland`
- `https://hypr.land/news/26_lua/`
- relevant upstream wiki pages to be located during execution

Changes:
- no repo changes beyond planning docs
- identify where upstream documents:
  - `hyprland.lua` entrypoint rules
  - Lua config syntax and helpers
  - examples for binds, rules, monitors, autostart, layouts, and environment handling
  - reload/restart behavior and any Lua-specific caveats
- inspect the cloned upstream repo for supporting metadata/examples that help planning, such as Lua stubs or config-related assets

Validation:
- record the exact upstream sources consulted
- record any missing documentation or unclear areas that block confident migration

Diff expectation:
- none yet; only planning knowledge

Commit target:
- none

### Phase 1: Current-shape inventory and gap mapping

Targets:
- live `~/.config/hypr/**`
- repo `config/desktops/hyprland-standalone/**`
- `modules/desktops/hyprland-standalone.nix`

Changes:
- map the current live modular config into semantic buckets:
  - monitors
  - env/session setup
  - input
  - appearance/decoration/animations
  - rules
  - binds
  - startup
  - helper scripts
- identify which live constructs are straightforward config translation versus which depend on shell scripts or runtime conventions
- identify what would first need parity sync before Lua migration begins

Validation:
- produce a file-by-file mapping from live runtime files to intended repo owners
- identify any no-owner or duplicated-owner surfaces

Diff expectation:
- none yet; this is planning inventory

Commit target:
- none

### Phase 2: Migration architecture decision

Targets:
- future repo structure only, not implementation yet

Changes:
- choose one of the migration approaches and justify it:
  - sync current modular hyprlang layout into repo first, then translate to Lua in-place
  - create parallel Lua-owned files while keeping the current hyprlang layout as rollback
  - other staged variant if better justified by upstream behavior
- decide the future repo-owned file layout, for example:
  - a single `hyprland.lua`
  - or a repo-owned modular Lua tree sourced/required from a root `hyprland.lua`
- define how helper shell scripts remain owned and referenced after migration
- define how rollback remains easy while upstream still supports hyprlang

Validation:
- architecture decision is explicit, small enough to execute in slices, and consistent with repo philosophy

Diff expectation:
- none yet; planning only

Commit target:
- none

### Phase 3: Execution slice design

Targets:
- future migration work plan only

Changes:
- break the eventual migration into small executable slices, for example:
  - parity sync of current live hyprlang runtime into repo
  - root `hyprland.lua` bootstrap introduction
  - monitors/env/input migration
  - appearance/layout/rules migration
  - binds migration
  - script/reference cleanup
  - final switch of provisioning path
- define for each slice:
  - files touched
  - runtime risks
  - validation commands
  - rollback method

Validation:
- every slice has a concrete validation story and a rollback path

Diff expectation:
- none yet; planning only

Commit target:
- none

## Risks

- Upstream Lua docs may still be evolving around the `0.55` window.
- The live runtime may include ad-hoc conventions that do not map cleanly to a future Lua structure.
- Trying to do parity sync and syntax migration in one pass would make failures much harder to reason about.
- Some live helper scripts may encode behavior that upstream Lua helpers can replace later, but not safely without runtime comparison.

## Definition of Done

- A dedicated migration plan exists for Hyprland Lua adoption.
- The plan is grounded in upstream's announced direction and the current live runtime shape.
- The plan explicitly separates parity sync from migration execution.
- No migration has been applied yet.
