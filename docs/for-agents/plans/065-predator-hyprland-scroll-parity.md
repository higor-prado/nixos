# Predator Hyprland Scroll Parity Plan

## Goal

Add a `Hyprland` path for `predator` that reproduces the current Niri workflow
as closely as possible while preserving the existing Niri setup intact.

The target is not to replace Niri immediately. The target is to build a
parallel `Hyprland` session using the `scrolling` layout, port the current
bindings and reserved-space behavior, validate parity, and only then decide
whether a cutover makes sense.

## Scope

In scope:
- `predator`
- `Hyprland`
- `scrolling` layout parity with the current Niri workflow
- `dms` integration
- keybindings, layout spacing, reserved areas, window rules, and launchers
- safe parallel host/config wiring so Niri remains available throughout

Out of scope:
- removing Niri during this work
- rewriting unrelated desktop subsystems
- changing keyboard, input-method, Steam, or theme behavior unless Hyprland
  requires explicit compositor-specific integration
- promising 1:1 parity for behaviors that do not have a real Hyprland
  equivalent before runtime validation proves it

## Current State

- `predator` currently wires the desktop stack in
  [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  through:
  - `nixos.desktop-dms-on-niri`
  - `nixos.niri`
  - `homeManager.desktop-dms-on-niri`
  - `homeManager.niri`

- The concrete DMS-on-Niri composition lives in
  [modules/desktops/dms-on-niri.nix](/home/higorprado/nixos/modules/desktops/dms-on-niri.nix)
  and provisions the mutable live overlay
  `~/.config/niri/custom.kdl`.

- The Niri feature owner is
  [modules/features/desktop/niri.nix](/home/higorprado/nixos/modules/features/desktop/niri.nix),
  which provisions the base config
  [config/apps/niri/config.kdl](/home/higorprado/nixos/config/apps/niri/config.kdl).

- The current DMS greeter configuration is explicitly pinned to
  `compositor.name = "niri"` in
  [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix).

- The main Niri behavior that needs parity is currently expressed in
  [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl),
  including:
  - `struts { left 315; right 315; top 100; }`
  - `focus-follows-mouse max-scroll-amount="0.1%"`
  - width and height presets
  - workspace bindings
  - launcher bindings
  - focus, move, floating, fullscreen, and sizing bindings
  - audio, media, brightness, and lock bindings

- Additional structural Niri behavior still lives in
  [config/apps/niri/config.kdl](/home/higorprado/nixos/config/apps/niri/config.kdl),
  including:
  - touchpad and pointer defaults
  - animations
  - `prefer-no-csd`
  - window rules

- `dms` already has compositor-specific settings for both Niri and Hyprland in
  [config/apps/dms/settings.json](/home/higorprado/nixos/config/apps/dms/settings.json),
  including:
  - `niriLayoutGapsOverride`
  - `hyprlandLayoutGapsOverride`
  - `niriOutputSettings`
  - `hyprlandOutputSettings`
  - compositor-specific cursor settings

- The recently stabilized keyboard, `fcitx5`, GTK, and Steam behavior lives in
  their own owners and should remain compositor-agnostic unless runtime proof
  shows that Hyprland needs an explicit compositor-scoped adjustment.

## Desired End State

- `Hyprland` is available on `predator` as a parallel desktop path.
- The `scrolling` layout reproduces the practical Niri workflow as closely as
  possible.
- Niri remains intact and testable while Hyprland is being built and validated.
- DMS works with Hyprland without losing the current reserved-space intent.
- The following behaviors are either ported or explicitly documented as
  non-equivalent:
  - launchers
  - workspaces `1..9`
  - focus left/right and vertical traversal
  - move/swap left/right
  - fullscreen and floating
  - width and height control
  - lock, media, audio, and brightness keys
  - reserved area equivalent to `left 315`, `right 315`, `top 100`
- Any eventual promotion from Niri to Hyprland happens only after runtime proof
  of parity and an explicit cutover decision.

## Main Technical Decisions

### 1. Build Hyprland in parallel, not in place

The current `predator` Niri path stays intact. Hyprland should be introduced as
a separate desktop path and, if needed, a separate concrete host configuration
such as `predator-hyprland`.

Reason:
- this avoids destructive cutover during implementation
- it keeps rollback trivial
- it allows iterative runtime testing without destabilizing the working session

### 2. Treat this as a new desktop composition

The correct repo pattern is:
- feature owner for `Hyprland`
- composition owner for `dms-on-hyprland`
- host owner wiring in `modules/hosts/predator.nix`

Do not graft Hyprland behavior into the Niri modules.

### 3. Preserve ownership boundaries

- `modules/features/desktop/hyprland.nix`
  owns the Hyprland feature
- `modules/desktops/dms-on-hyprland.nix`
  owns the concrete DMS + Hyprland composition
- `modules/features/desktop/dms.nix`
  only receives the narrow DMS integration changes required for Hyprland
- `modules/hosts/predator.nix`
  owns the concrete host composition and any parallel host wiring

### 4. Port practical workflow first, not cosmetic perfection

The first success criterion is functional parity:
- same launchers
- same workspace workflow
- same layout spacing intent
- same reserved-space behavior
- same core movement/focus shortcuts

Fine-grained visual tuning should come after functional parity.

### 5. Document non-equivalent behavior before any cutover

Some Niri semantics may not map 1:1 to Hyprland. Examples that require explicit
investigation:
- `toggle-column-tabbed-display`
- `consume-or-expel-window-*`
- `always-center-single-column`
- `center-focused-column "on-overflow"`
- `focus-follows-mouse max-scroll-amount="0.1%"`

If any of these do not have a real equivalent, the plan must document that
clearly before any decision to promote Hyprland as the default path.

## Parity Targets

### Must Match

- `Super+Space` launcher
- `Super+Ctrl+T/F/B/V/E` app launchers
- `Super+1..9` workspace focus
- `Super+Alt+1..9` move to workspace
- `Super+Left/Right`, `Super+H/L` focus left/right
- `Super+Alt+Left/Right`, `Super+Alt+H/L` move left/right
- `Alt+F4` close
- `Super+M` fullscreen
- `Super+Alt+Slash` floating toggle
- `Super+BracketLeft/Right` width control or equivalent
- lock, media, brightness, and audio bindings
- reserved area equivalent to:
  - top `100`
  - left `315`
  - right `315`

### Must Be Close

- width presets
- vertical navigation inside the scroll layout
- focus centering behavior
- border and active/inactive emphasis
- window spacing/gaps
- animations

### Must Be Explicitly Investigated

- tabbed-column behavior
- consume/expel behavior
- Niri overview behavior
- `prefer-no-csd` and related window-rule semantics
- GNOME app-specific decoration behavior

## Phases

### Phase 0: Freeze the Niri Baseline

Targets:
- [config/apps/niri/config.kdl](/home/higorprado/nixos/config/apps/niri/config.kdl)
- [config/desktops/dms-on-niri/custom.kdl](/home/higorprado/nixos/config/desktops/dms-on-niri/custom.kdl)
- [config/apps/dms/settings.json](/home/higorprado/nixos/config/apps/dms/settings.json)
- this plan

Changes:
- inventory the current Niri behavior that must be preserved
- map each relevant binding and layout behavior into one of:
  - exact Hyprland target
  - approximate Hyprland target
  - open parity gap
- capture current reserved-space and layout assumptions as source-of-truth

Validation:
- `rg -n 'struts|preset-|center-|toggle-column-tabbed-display|consume-or-expel|focus-follows-mouse' config/desktops/dms-on-niri/custom.kdl`
- `rg -n 'window-rule|prefer-no-csd|animations|touchpad|mouse' config/apps/niri/config.kdl`
- `rg -n 'niriLayout|hyprlandLayout|OutputSettings|cursorSettings' config/apps/dms/settings.json`

Diff expectation:
- no repo diff

Commit target:
- none

### Phase 1: Add a Hyprland Feature Owner

Targets:
- [modules/features/desktop/hyprland.nix](/home/higorprado/nixos/modules/features/desktop/hyprland.nix)
- [config/apps/hypr/](/home/higorprado/nixos/config/apps/hypr)

Changes:
- add a new top-level Hyprland feature owner
- own package enablement, portal wiring, and base config provisioning
- provision a tracked base Hyprland config under `config/apps/hypr/`
- keep the feature isolated from host cutover decisions

Validation:
- `./scripts/check-extension-contracts.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- Hyprland becomes available as a feature
- current Niri host path remains unchanged

Commit target:
- `feat(hyprland): add hyprland feature owner`

### Phase 2: Add a DMS-on-Hyprland Composition

Targets:
- [modules/desktops/dms-on-hyprland.nix](/home/higorprado/nixos/modules/desktops/dms-on-hyprland.nix)
- [config/desktops/dms-on-hyprland/](/home/higorprado/nixos/config/desktops/dms-on-hyprland)
- [modules/features/desktop/dms.nix](/home/higorprado/nixos/modules/features/desktop/dms.nix)

Changes:
- add a concrete DMS + Hyprland composition parallel to `dms-on-niri`
- provision mutable-copy-once Hyprland overlay files in `~/.config/hypr/`
- teach DMS the narrow composition-scoped Hyprland wiring it needs
- keep the existing DMS-on-Niri composition intact

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- repo gains a parallel Hyprland composition
- current Niri composition remains untouched

Commit target:
- `feat(desktop): add dms-on-hyprland composition`

### Phase 3: Add a Safe Parallel Predator Configuration

Targets:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)

Changes:
- refactor host wiring so shared desktop-independent imports stay shared
- add a second concrete host configuration, for example
  `configurations.nixos.predator-hyprland`
- keep the current `predator` configuration on Niri
- wire the new Hyprland configuration with:
  - the same hardware imports
  - the same user/groups
  - the same non-desktop features
  - Hyprland-specific desktop imports only

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator-hyprland.config.system.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator-hyprland.config.system.build.toplevel`

Diff expectation:
- Niri remains the stable default path
- Hyprland becomes safely buildable and testable in parallel

Commit target:
- `feat(predator): add parallel hyprland configuration`

### Phase 4: Port Layout, Reserved Space, and Core Bindings

Targets:
- [config/apps/hypr/](/home/higorprado/nixos/config/apps/hypr)
- [config/desktops/dms-on-hyprland/](/home/higorprado/nixos/config/desktops/dms-on-hyprland)
- [config/apps/dms/settings.json](/home/higorprado/nixos/config/apps/dms/settings.json)

Changes:
- configure Hyprland to use the `scrolling` layout
- port the current Niri workflow into Hyprland dispatchers and layout settings
- implement reserved space equivalent to:
  - top `100`
  - left `315`
  - right `315`
- map DMS compositor-specific settings for Hyprland
- port launcher, workspace, focus, move, float, fullscreen, lock, media,
  brightness, and audio bindings

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator-hyprland.config.system.build.toplevel`
- runtime checks inside a Hyprland session

Diff expectation:
- Hyprland session reaches core functional parity for the main workflow
- Niri still works unchanged

Commit target:
- `feat(hyprland): port core workflow from niri`

### Phase 5: Port Rules and App-Specific Behavior

Targets:
- [config/apps/hypr/](/home/higorprado/nixos/config/apps/hypr)

Changes:
- translate important Niri window rules into Hyprland equivalents where
  possible
- review compositor-specific helper processes and remove Niri-only assumptions
  from the Hyprland path
- validate app behavior for the main desktop apps used on `predator`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build --no-link path:$PWD#nixosConfigurations.predator-hyprland.config.system.build.toplevel`
- runtime checks in Hyprland for:
  - Nautilus
  - Firefox or Chromium
  - VSCode
  - Steam
  - Emacs or Zed

Diff expectation:
- Hyprland app behavior is acceptable for the main daily-driver apps

Commit target:
- `fix(hyprland): port rules and app behavior`

### Phase 6: Runtime Parity Review and Cutover Decision

Targets:
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)

Changes:
- run a real-session parity checklist in Hyprland
- compare against the Phase 0 baseline
- document any remaining non-equivalent behaviors
- only if parity is accepted:
  - decide whether to promote Hyprland as the default `predator` path
  - or keep both configurations available

Validation:
- `nh os test path:$PWD#predator-hyprland`
- manual session checklist for launchers, workspaces, movement, reserved space,
  lock, media, and the main apps
- rollback proof with the current Niri path still available

Diff expectation:
- no forced cutover before parity is proven
- rollback to Niri remains straightforward

Commit target:
- `refactor(predator): promote hyprland after parity`

## Risks

- Some Niri semantics may not have a true Hyprland equivalent.
- DMS may contain compositor assumptions beyond the currently visible settings.
- Reserved-space behavior may require monitor-specific Hyprland rules.
- A mutable-copy-once desktop config can drift from templates if parity checks
  are skipped.
- If Hyprland behavior differs materially in areas like tabbed columns or
  focus-centering, the plan must stop short of cutover and record that clearly.

## Definition of Done

- `Hyprland` is installed and buildable for `predator`
- a parallel DMS-on-Hyprland path exists
- the current Niri path remains intact and usable
- the Hyprland session reproduces the main Niri workflow closely enough for
  real testing
- reserved-space behavior for the DMS shell is implemented
- major daily-driver apps behave acceptably in the Hyprland session
- all known non-equivalent behaviors are documented before any cutover
- validation gates pass
- rollback to the current Niri path remains simple
