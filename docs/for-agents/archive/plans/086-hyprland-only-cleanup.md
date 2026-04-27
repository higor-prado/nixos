# Hyprland-Only Desktop Cleanup

## Goal

Remove the live Niri/DMS/Noctalia desktop surfaces from the predator runtime and repository maintenance surface while preserving an easy rollback path to the pre-Hyprland Niri state through git tags/branches.

## Scope

In scope:
- Create/confirm the git rollback point for the pre-Hyprland migration state.
- Do the cleanup only on a new branch from the current Hyprland runtime.
- Keep predator as a Hyprland standalone desktop.
- Remove live Niri, DMS, DMS wallpaper, DMS AWWW, and Noctalia modules, inputs, payloads, tests, fixtures, scripts, and living documentation.
- Keep Hyprland-related runtime: Hyprland, ReGreet/greetd, xdg-desktop-portal-hyprland/gtk, Waybar, Rofi, Mako, session applets, Satty, Wlogout, Waypaper/AWWW, Keyrs, gaming, themes, and shared Wayland tools. Do not keep automatic idle lock/DPMS through hypridle/hyprlock.
- Keep historical archived docs unless they block a gate; history may mention removed desktops.

Out of scope:
- Switching predator away from Hyprland.
- Deleting private override files or reading real private files.
- Runtime deletion of old mutable `$HOME/.config/niri`, `$HOME/.config/DankMaterialShell`, or persisted DMS state; source cleanup can stop declaring them, but manual disk cleanup is separate.
- Redesigning the dendritic module pattern or adding selector options.

## Current State

- Current branch observed: `main`.
- Worktree is dirty before this cleanup plan; do not branch/tag/clean until existing local changes are intentionally committed, stashed, or otherwise protected.
- Current Hyprland migration appears to start at `b3aa878 feat(desktop): add Hyprland desktop composition`; its parent is `3f0f271 feat(desktop): add vivaldi and floorp browsers with catppuccin theme`.
- There is older historical Hyprland removal at `9c59484 chore(hyprland): remove hyprland and dead code`; confirm whether `3f0f271` is the desired pre-Hyprland rollback point for this migration.
- `modules/hosts/predator.nix` still carries three desktop import lists: `nixosDesktopNiri`, `nixosDesktopNoctalia`, and `nixosDesktopHyprland`, with commented selection lines for the old desktops.
- Live Niri/DMS/Noctalia surfaces currently include:
  - `flake.nix` inputs: `dms`, `noctalia`, `niri`, `dms-awww-src`.
  - `modules/desktops/dms-on-niri.nix`
  - `modules/desktops/niri-standalone.nix`
  - `modules/desktops/noctalia-on-niri.nix`
  - `modules/features/desktop/niri.nix`
  - `modules/features/desktop/dms.nix`
  - `modules/features/desktop/dms-wallpaper.nix`
  - `modules/features/desktop/noctalia.nix`
  - `config/apps/niri/`
  - `config/apps/dms/`
  - `config/desktops/dms-on-niri/`
  - `config/desktops/niri-standalone/`
  - `config/desktops/noctalia-on-niri/`
  - `pkgs/dms-awww.nix` and `pkgs/default.nix` attribute `dms-awww`.
- Other live cleanup points:
  - `modules/features/core/nix-settings-desktop.nix` still trusts Noctalia Cachix.
  - `hardware/predator/persisted-paths.nix` persists `/var/lib/dms-greeter`.
  - `hardware/predator/hardware/gpu-nvidia.nix` has an NVIDIA app profile for `niri`.
  - `lib/_helpers.nix` has a Niri-specific comment for generic portal helpers.
  - `modules/features/desktop/desktop-apps.nix` removes `dms-open.desktop` from MIME handlers.
  - `modules/features/desktop/xwayland.nix` may become unused because Hyprland owns XWayland via `programs.hyprland.xwayland.enable = true`.
- Tests/scripts still model Niri/DMS desktop experiences:
  - `scripts/check-desktop-composition-matrix.sh`
  - `scripts/new-host-skeleton.sh`
  - `tests/scripts/new-host-skeleton-fixture-test.sh`
  - `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
  - `scripts/check-config-contracts.sh`
  - `scripts/check-runtime-smoke.sh`
- Living docs that need review include:
  - `AGENTS.md`
  - `docs/for-agents/001-repo-map.md`
  - `docs/for-agents/003-module-ownership.md`
  - `docs/for-agents/006-extensibility.md`
  - `docs/for-humans/01-philosophy.md`
  - `docs/for-humans/workflows/104-add-desktop-experience.md`
  - active plan/current files under `docs/for-agents/plans/` and `docs/for-agents/current/` if they still mention removed desktops and remain active.

## Desired End State

- A confirmed annotated tag points at the chosen pre-Hyprland Niri baseline, likely `3f0f271`, for easy future rollback.
- Cleanup work happens on a dedicated branch, e.g. `cleanup/hyprland-only`, from the current clean Hyprland state.
- `predator` imports only the Hyprland desktop composition and Hyprland-supporting feature modules.
- Removed desktop inputs are gone from `flake.nix` and pruned from `flake.lock`.
- No live Nix/module/script/test/doc path outside archives refers to Niri, DMS, DMS AWWW, or Noctalia unless there is an explicit, justified exception.
- Validation gates pass after each meaningful slice and full predator build succeeds.
- `nvd` closure diff shows expected removals and no accidental removal of Hyprland runtime components.

## Phases

### Phase 0: Git safety, baseline, and rollback anchor

Targets:
- Git state only; no source cleanup.

Changes:
- Stop if `git status --short` is not clean. Protect current uncommitted work first.
- Confirm the intended pre-Hyprland tag target:
  - likely `3f0f271`, parent of `b3aa878 feat(desktop): add Hyprland desktop composition`.
- Create an annotated tag, for example:
  - `git tag -a pre-hyprland-migration 3f0f271 -m "pre Hyprland migration baseline"`
- Optional extra safety tag at the current mixed Hyprland/Niri-capable state before deletion:
  - `git tag -a pre-hyprland-only-cleanup HEAD -m "before Hyprland-only desktop cleanup"`
- Create and switch to the cleanup branch from current clean HEAD:
  - `git switch -c cleanup/hyprland-only`
- Build a baseline closure before cleanup:
  - `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-hyprland-before-cleanup`

Validation:
- `git status --short`
- `git tag --list 'pre-hyprland*' 'pre-hyprland-only*'`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- No source diff from this phase, except optional tag refs outside the working tree.

Commit target:
- None for tags/branch. If any safety doc is changed, use `docs(desktop): document hyprland cleanup branch plan`.

### Phase 1: Collapse predator to one Hyprland desktop path

Targets:
- `modules/hosts/predator.nix`

Changes:
- Remove `nixosDesktopNiri`, `nixosDesktopNoctalia`, `hmDesktopNiri`, and `hmDesktopNoctalia` lists.
- Remove commented old selector lines.
- Keep a single explicit Hyprland import path:
  - NixOS: `inputs.hyprland.nixosModules.default`, `inputs.keyrs.nixosModules.default`, `nixos.desktop-hyprland-standalone`, `nixos.regreet`, `nixos.fcitx5`, `nixos.gaming`, `nixos.gnome-keyring`, `nixos.keyrs`, `nixos.hyprland`, `nixos.nautilus`.
  - Home Manager: current Hyprland app parity modules including `homeManager.desktop-hyprland-standalone`, `homeManager.hyprland`, `homeManager.rofi`, `homeManager.wlogout`, `homeManager.mako`, `homeManager.qt-theme`, `homeManager.session-applets`, `homeManager.waypaper`, `homeManager.waybar`, `homeManager.satty`, and retained desktop/media/theme/tool modules.
- Keep host composition explicit; do not introduce selectors or `custom.*` toggles.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.programs.hyprland.enable`
- `nix eval path:$PWD#nixosConfigurations.predator.config.programs.regreet.enable`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `./scripts/check-config-contracts.sh` after its expectations are still compatible, or defer if Phase 3 is required first.

Diff expectation:
- Predator host file becomes smaller but runtime should still select the same Hyprland desktop as before.

Commit target:
- `refactor(hosts): make predator hyprland-only`

### Phase 2: Remove dead desktop modules, payloads, package, inputs, and host leftovers

Targets:
- `flake.nix`
- `flake.lock`
- `modules/desktops/`
- `modules/features/desktop/`
- `modules/features/core/nix-settings-desktop.nix`
- `config/apps/`
- `config/desktops/`
- `pkgs/`
- `hardware/predator/persisted-paths.nix`
- `hardware/predator/hardware/gpu-nvidia.nix`
- `lib/_helpers.nix`
- `modules/features/desktop/desktop-apps.nix`

Changes:
- Delete Niri/DMS/Noctalia composition files:
  - `modules/desktops/dms-on-niri.nix`
  - `modules/desktops/niri-standalone.nix`
  - `modules/desktops/noctalia-on-niri.nix`
- Delete feature owners:
  - `modules/features/desktop/niri.nix`
  - `modules/features/desktop/dms.nix`
  - `modules/features/desktop/dms-wallpaper.nix`
  - `modules/features/desktop/noctalia.nix`
- Delete payload directories:
  - `config/apps/niri/`
  - `config/apps/dms/`
  - `config/desktops/dms-on-niri/`
  - `config/desktops/niri-standalone/`
  - `config/desktops/noctalia-on-niri/`
- Delete DMS AWWW package support:
  - `pkgs/dms-awww.nix`
  - `dms-awww` attribute from `pkgs/default.nix`.
- Remove flake inputs:
  - `dms`
  - `noctalia`
  - `niri`
  - `dms-awww-src`
- Refresh/prune `flake.lock` after input removal.
- Remove Noctalia Cachix substituter/key from `modules/features/core/nix-settings-desktop.nix`.
- Remove `/var/lib/dms-greeter` from `hardware/predator/persisted-paths.nix`.
- Remove `niri` NVIDIA app profile from `hardware/predator/hardware/gpu-nvidia.nix`.
- Update `lib/_helpers.nix` comment so portal helpers are not described as Niri-specific.
- Remove `dms-open.desktop` from `modules/features/desktop/desktop-apps.nix` MIME cleanup.
- Audit `modules/features/desktop/xwayland.nix`; if it has no remaining importer and Hyprland already enables XWayland internally, delete it as dead code.
- Keep `modules/features/desktop/waypaper.nix` and `pkgs.awww` because Waypaper/AWWW is currently part of the Hyprland runtime, not DMS-only.

Validation:
- `nix flake metadata`
- `./scripts/check-flake-inputs-used.sh`
- `./scripts/check-feature-publisher-name-match.sh`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

Diff expectation:
- Deleted source files and pruned flake inputs for Niri/DMS/Noctalia only.
- Hyprland, ReGreet, Waybar, Mako, Rofi, Wlogout, Satty, Waypaper/AWWW, Keyrs, and shared desktop tooling remain.

Commit target:
- `refactor(desktop): remove niri dms and noctalia surfaces`
- `chore(lock): prune removed desktop inputs` if lock churn is substantial enough to split.

### Phase 3: Narrow tests, fixtures, and runtime smoke to Hyprland

Targets:
- `scripts/check-desktop-composition-matrix.sh`
- `scripts/new-host-skeleton.sh`
- `tests/scripts/new-host-skeleton-fixture-test.sh`
- `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`
- `scripts/check-config-contracts.sh`
- `scripts/check-runtime-smoke.sh`
- `tests/pyramid/shared-script-registry.tsv` only if script set changes; likely no change.

Changes:
- Change the desktop composition matrix to evaluate only `hyprland-standalone`.
- Change `scripts/new-host-skeleton.sh` default desktop experience from `dms-on-niri` to `hyprland-standalone`.
- Replace Niri/DMS desktop skeleton payload with Hyprland imports.
- Update fixture invocation and expected fixture output to Hyprland.
- Rewrite config contracts to assert the active Hyprland runtime rather than carrying Niri/DMS absence checks.
- Rewrite runtime smoke to report/check Hyprland/ReGreet/portal/session-app features instead of `programs.niri` and DMS units.
- Ensure script help/examples no longer advertise deleted desktop experiences.

Validation:
- `./scripts/check-desktop-composition-matrix.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-config-contracts.sh`
- `bash tests/scripts/gate-cli-contracts-test.sh` if runtime smoke CLI/help behavior is touched materially.
- `./scripts/run-validation-gates.sh structure`

Diff expectation:
- Tests and fixtures become Hyprland-only; no deleted module names remain in live test fixtures.

Commit target:
- `test(desktop): narrow desktop checks to hyprland`
- `refactor(scripts): generate hyprland desktop skeletons`

### Phase 4: Update living documentation and active agent docs

Targets:
- `AGENTS.md`
- `README.md` if needed
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-humans/01-philosophy.md`
- `docs/for-humans/02-structure.md` if app payload list changes
- `docs/for-humans/workflows/104-add-desktop-experience.md`
- Active docs under `docs/for-agents/plans/` and `docs/for-agents/current/`.

Changes:
- Update repo maps to remove deleted Niri/DMS/Noctalia files and list only the Hyprland composition under `modules/desktops/`.
- Replace examples that use `niri` with `hyprland` or neutral `my-feature` examples.
- Change AGENTS mutable-copy example away from `dms`, e.g. `waybar` or `waypaper`.
- If active plans are completed or obsolete, archive them according to the active-vs-archive rule; otherwise update only living active docs that would mislead future work.
- Do not rewrite historical archive docs merely to remove old mentions.

Validation:
- `./scripts/check-docs-drift.sh`
- `rg -n -i 'niri|dms|noctalia|dms-awww|DankMaterialShell' README.md AGENTS.md docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans scripts tests modules hardware config pkgs flake.nix --glob '!docs/for-agents/archive/**'`
  - Expected: no matches, or only reviewed intentional exceptions.

Diff expectation:
- Living docs describe Hyprland-only runtime and no longer point to deleted paths.

Commit target:
- `docs(desktop): document hyprland-only runtime`

### Phase 5: Full validation and closure diff

Targets:
- Whole repo.

Changes:
- None unless validation reveals issues.

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(nix eval --json --expr 'builtins.attrNames (builtins.getFlake "path:'"$PWD"'").nixosConfigurations.predator.config.home-manager.users' | jq -r '.[0]').home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.<user>.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-hyprland-only`
- `nix run nixpkgs#nvd -- diff /tmp/predator-hyprland-before-cleanup /tmp/predator-hyprland-only`
- `./scripts/check-repo-public-safety.sh`
- Prefer final full gate when time allows: `./scripts/run-validation-gates.sh all`.

Diff expectation:
- Expected removals: Niri compositor packages, xwayland-satellite if only Niri used it, Dank Material Shell/DSearch/DMS greeter pieces, Noctalia shell, DMS AWWW package/support, Noctalia Cachix config, DMS/Niri config payloads.
- Expected retained: Hyprland, ReGreet/greetd, xdg-desktop-portal-hyprland, xdg-desktop-portal-gtk, Waybar, Rofi, Mako, Satty, Wlogout, session applets, Waypaper/AWWW, Keyrs, shared Wayland tools, themes, gaming stack. Expected removals also include automatic idle lock/DPMS pieces (`hypridle`/`hyprlock`).

Commit target:
- Fixup commits as needed, then keep logical commits focused per phase.

## Risks

- The current dirty worktree may already contain uncommitted Hyprland fixes; branching before protecting them can mix unrelated work into cleanup.
- Tagging `3f0f271` assumes `b3aa878` is the first commit of the current Hyprland migration. Confirm this before creating the rollback tag.
- Removing inputs without updating every reference will break auto-import evaluation or `check-flake-inputs-used.sh`.
- `flake.lock` may have large churn; inspect it separately from source cleanup.
- Removing persisted path declarations does not delete old data from disk. Manual cleanup of `/var/lib/dms-greeter` or mutable user configs should be a separate, explicit operational step.
- Archived docs will still mention historical Niri/DMS/Noctalia work; this is acceptable unless a living-doc gate includes those paths.
- `waypaper` uses AWWW but is currently part of Hyprland; avoid deleting it just because DMS also used AWWW.

## Definition of Done

- Pre-Hyprland rollback tag exists and branch strategy is confirmed.
- Cleanup branch contains focused commits for host collapse, dead surface deletion, tests/scripts, docs, and lock cleanup.
- `predator` evaluates and builds with Hyprland-only imports.
- Live source no longer contains Niri/DMS/Noctalia modules, payloads, flake inputs, active tests, fixtures, or living docs.
- Required gates and safety check pass.
- Closure diff is reviewed and matches expected removals/retentions.
