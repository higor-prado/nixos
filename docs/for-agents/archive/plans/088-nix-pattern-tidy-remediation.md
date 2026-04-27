# Nix Pattern Tidy Remediation Plan

## Goal

Resolve the maintainability and architecture-alignment findings from the Hyprland cleanup audit in small, safe, testable slices, while preserving the repo's dendritic model and avoiding any unrelated runtime/version changes.

Source audit:

- `docs/for-agents/archive/reports/087-hyprland-cleanup-review-and-nix-pattern-audit.md`

## Scope

In scope:

- Remove theme source-of-truth duplication around Catppuccin flavor/accent.
- Separate non-trivial tray icon patch derivation logic from the shared theme catalog.
- Make predator custom package use derive from the already-evaluated module `pkgs` instead of a second `nixpkgs` import.
- Clarify Aurelius-specific service owner names or document why they are intentionally host-specific.
- Review the Cerebelo RK3588 `_module.args` bridge and either document the exception or replace it if a safe upstream-compatible path exists.
- Clarify the Spicetify external module import ownership in `music-client`.
- Clarify or harden the AIOStreams/Tailscale Serve ownership model.
- Remove low-risk Nix lint noise from feature modules.
- Keep active docs and repo map synchronized.

Out of scope:

- Hyprland package/input/version changes.
- New desktop behavior or visual redesign.
- Runtime switch/application on a host unless a phase explicitly calls for runtime validation.
- Editing, reading, or referencing real private override files under `private/**`.
- Refactoring generated hardware configuration files solely for lint style.
- Replacing the dendritic pattern, adding selector booleans, adding role frameworks, or introducing `specialArgs` / `extraSpecialArgs`.

## Non-negotiable safety rules

- Start each implementation slice from a clean worktree.
- Do not update `flake.lock` unless the phase explicitly requires it. None of the planned phases should require input updates.
- If a tool or eval mutates `flake.lock` incidentally, inspect the diff and restore it unless the user explicitly approves the update.
- Keep commits focused: one finding or tightly related finding group per commit.
- Run `./scripts/check-repo-public-safety.sh` before every commit.
- For anything touching login/session/board/server runtime, prefer documentation or tiny code changes unless evaluation and rollback are clear.

## Current state

- Branch carrying the Hyprland-only cleanup: `cleanup/hyprland-only`.
- Active plan still intentionally present: `docs/for-agents/plans/085-hyprland-session-service-ordering.md`.
- The audit report found no critical architecture break.
- The remaining items are maintainability, source-of-truth, owner naming, and small lint/style issues.

## Desired end state

- Theme flavor/accent are defined in one shared catalog source and consumed by all theme owners that need them.
- The shared theme catalog is readable as a catalog, not as a large embedded package-building script.
- Predator host composition no longer instantiates a separate `nixpkgs` only to build local packages for Home Manager.
- Aurelius-specific service modules either have owner names that admit they are Aurelius-specific, or have explicit documentation explaining the host-specific contract.
- Cerebelo's RK3588 upstream compatibility bridge is explicitly documented, or safely removed/replaced after proof.
- `music-client` clearly owns or exposes its Spicetify dependency by an intentional documented pattern.
- AIOStreams is clearly the single source of truth for its Tailscale Serve route, or the route ownership is split into a safer dedicated owner.
- `deadnix` has no actionable feature-module warnings after planned cleanup, except any intentionally documented exceptions.
- Structure validation and full validation pass.

## Phase 0 — Baseline and guard rails

Targets:

- No code changes.

Steps:

1. Confirm clean worktree:
   ```bash
   git status --short --branch
   ```
2. Confirm active branch and decide whether to continue on the current cleanup branch or create a follow-up branch, for example:
   ```bash
   git switch -c tidy/nix-pattern-remediation
   ```
3. Optional rollback tag before code remediation:
   ```bash
   git tag -a pre-nix-pattern-tidy HEAD -m "before Nix pattern tidy remediation"
   ```
4. Capture baseline validation:
   ```bash
   ./scripts/run-validation-gates.sh structure
   nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
   ```
5. Capture baseline lint output for comparison:
   ```bash
   nix run --no-write-lock-file nixpkgs#deadnix -- --fail flake.nix modules hardware lib pkgs || true
   ```
6. If any command changes `flake.lock`, inspect and restore unless explicitly intended:
   ```bash
   git diff -- flake.lock
   git checkout -- flake.lock
   ```

Validation:

- `git status --short` is clean after baseline commands.
- Structure gate passes before remediation starts.

Commit target:

- None.

## Phase 1 — Theme source of truth: make Zen consume the shared catalog

Audit finding addressed:

- F-001: Zen theme owner duplicates Catppuccin flavor/accent.

Targets:

- `modules/features/desktop/theme-zen.nix`
- possibly `docs/for-agents/001-repo-map.md` if wording needs clarification.

Changes:

- Import `modules/features/desktop/_theme-catalog.nix` from `theme-zen.nix`.
- Derive `flavor` and `accent` from that catalog.
- Keep only Zen-specific capitalization/path construction in `theme-zen.nix`.
- Remove now-unused lambda arguments.

Implementation intent:

- `theme-base.nix`, `regreet.nix`, and `theme-zen.nix` should all consume the same theme catalog for shared theme facts.
- Do not change the actual selected theme values (`mocha` / `lavender`) in this phase.

Validation:

```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).catppuccin.flavor
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Additional review check:

```bash
rg -n 'flavor = "mocha"|accent = "lavender"' modules/features/desktop/theme-zen.nix
```

Expected result:

- No duplicated hardcoded flavor/accent remains in `theme-zen.nix`.
- The evaluated theme remains unchanged.

Commit target:

- `refactor(theme): make zen consume shared theme catalog`

## Phase 2 — Split patched tray icon derivation from the theme catalog

Audit finding addressed:

- F-005: theme catalog owns substantial icon-patching build logic.

Targets:

- `modules/features/desktop/_theme-catalog.nix`
- a feature-private underscore helper adjacent to the theme owner.
- `docs/for-agents/001-repo-map.md`

Changes:

- Move the `pkgs.runCommand` derivation that patches tray SVG colors out of `_theme-catalog.nix`.
- Keep the new helper feature-private by using an underscore-prefixed adjacent file.
- Have `_theme-catalog.nix` call/reference the helper and continue to expose the same `iconTheme` shape.
- Preserve the package name and icon theme name unless there is a concrete reason to change them.
- Document the new underscore helper in the repo map's feature-private files section.

Safety constraints:

- No visible theme change is intended.
- Do not alter Waybar config or tray icon mappings in this phase.

Validation:

```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).gtk.iconTheme.name
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
```

Expected result:

- Evaluated GTK icon theme remains `Papirus-Dark`.
- Home build succeeds.
- `_theme-catalog.nix` is shorter and reads as a catalog again.

Commit target:

- `refactor(theme): split patched tray icon derivation from catalog`

## Phase 3 — Derive predator custom packages from evaluated `pkgs`

Audit finding addressed:

- F-003: predator host imports custom package set through a separate `nixpkgs` instantiation.

Targets:

- `modules/hosts/predator.nix`

Changes:

- Remove the top-level `customPkgs` binding that imports `inputs.nixpkgs` separately.
- Inside the Home Manager user lambda, derive local packages from the already provided `pkgs`:
  ```nix
  let
    customPkgs = import ../../pkgs { inherit pkgs inputs; };
  in
  { ... }
  ```
- Keep `system = "x86_64-linux"` if still needed for `nixpkgs.hostPlatform` and host-level flake package references.
- Do not change the package list itself.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path.drvPath
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Diff expectation:

- No runtime package changes.
- Only package-set construction location changes.

Commit target:

- `refactor(hosts): derive predator packages from evaluated pkgs`

## Phase 4 — Clarify Aurelius-specific service owners

Audit finding addressed:

- F-002: host-specific Aurelius identity embedded in generically named feature modules.

Targets:

- `modules/features/system/aurelius-github-runner.nix`
- `modules/features/system/aurelius-attic-server.nix`
- `modules/features/system/aurelius-attic-local-publisher.nix`
- `modules/hosts/aurelius.nix`
- `docs/for-agents/001-repo-map.md` if feature list/docs mention these owners.

Decision point:

- If these services are intentionally Aurelius-only, prefer owner names that make that visible.
- If they should become reusable, introduce a narrow, explicit configuration surface only if there are at least two real consumers or a concrete near-term need.

Preferred safe remediation:

- Rename the feature files and published module names to Aurelius-specific owners.
- Update `modules/hosts/aurelius.nix` imports to the new names.
- Keep internal service behavior unchanged.
- Keep private binding comments generic and public-safe; do not read private host files.

Alternative remediation if rename churn is not desired:

- Add comments near each owner explaining that the module is intentionally a concrete Aurelius service owner imported only by `modules/hosts/aurelius.nix`.
- Update docs to describe this as a host-specific feature owner exception.

Validation:

```bash
./scripts/check-feature-publisher-name-match.sh
./scripts/check-config-contracts.sh
nix eval path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Diff expectation:

- If renaming, evaluation behavior should be unchanged aside from attr names and import references.
- No service settings, secrets, tokens, URLs, or private paths are added.

Commit target:

- Preferred rename path: `refactor(system): name aurelius-specific service owners explicitly`
- Documentation-only path: `docs(system): document aurelius-specific service owners`

## Phase 5 — Review Cerebelo RK3588 module-args bridge

Audit finding addressed:

- F-004: Cerebelo host uses `_module.args` as an upstream board compatibility bridge.

Targets:

- `modules/hosts/cerebelo.nix`
- possibly `hardware/cerebelo/board.nix`
- `docs/for-agents/001-repo-map.md` or a short code comment if documenting the exception.

Required investigation before editing:

- Inspect the upstream RK3588 module interface in the locked input available through the Nix store/eval path.
- Determine whether `rk3588` and `nixos-generators` are still required as module arguments.
- Determine whether the bridge can be scoped closer to `hardware/cerebelo/board.nix` without losing access to required inputs.

Safe preferred outcome:

- If the bridge is still required, keep it but add a concise comment explaining:
  - it is an upstream board compatibility shim;
  - it is not repo-local runtime context plumbing;
  - it should not be copied as a pattern for new features.

Only-if-proven outcome:

- If upstream exposes equivalent options or no longer needs these args, remove or replace `_module.args`.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.cerebelo.config.nixpkgs.hostPlatform.system
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Runtime caution:

- Do not switch Cerebelo from this phase without an explicit human request.
- Board/boot changes require separate runtime acceptance and rollback planning.

Commit target:

- Documentation/comment path: `docs(cerebelo): document rk3588 module args bridge`
- Code removal path only if proven safe: `refactor(cerebelo): remove rk3588 module args bridge`

## Phase 6 — Clarify Spicetify ownership inside `music-client`

Audit finding addressed:

- F-006: `music-client` hides an external Home Manager module import inside the lower-level module.

Targets:

- `modules/features/desktop/music-client.nix`
- optionally `docs/for-agents/001-repo-map.md`

Decision point:

- If `music-client` is intended to own the entire Spotify/Spicetify stack, keep the external import encapsulated and document that this is an intentional implementation detail.
- If major upstream imports must always be visible in host composition, split the Spicetify integration into a clearly named published module and add it explicitly to the host import list.

Preferred low-risk remediation:

- Add a concise owner comment in `music-client.nix` explaining that this feature owns the Spicetify Home Manager module import because it is only meaningful as part of the music client capability.
- Do not split unless future hosts need Spotify without the rest of the music client feature.

Validation:

```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).programs.spicetify.enable
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Commit target:

- Comment/docs path: `docs(desktop): document music-client spicetify ownership`
- Split path if chosen: `refactor(desktop): expose spicetify music client owner explicitly`

## Phase 7 — Clarify or harden AIOStreams Tailscale Serve ownership

Audit finding addressed:

- F-007: `aiostreams` has host-specific operational ownership and runs a global `tailscale serve reset`.

Targets:

- `modules/features/media/aiostreams.nix`
- possibly `modules/hosts/cerebelo.nix`
- possibly docs if ownership is documented.

Investigation:

```bash
rg -n 'tailscale serve|services\.tailscale|allowedTCPPorts' modules hardware docs/for-agents/[0-9][0-9][0-9]-*.md docs/for-humans -g '*.nix' -g '*.md'
```

Decision point:

- If AIOStreams is the only tracked Tailscale Serve route for Cerebelo, document that this module is the single owner of that route state and that `reset` is intentional.
- If more tracked routes exist or are planned, create a single Tailscale Serve route owner and move route composition there instead of letting individual apps reset global serve state.

Preferred safe remediation for current single-route state:

- Add a precise code comment before the service script explaining why `tailscale serve reset` is safe in this repo state.
- Avoid behavior change unless runtime tests can be performed on Cerebelo.

Validation:

```bash
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Optional runtime validation after explicit user approval:

```bash
systemctl status tailscale-serve-aiostreams --no-pager
sudo tailscale serve status
```

Commit target:

- Documentation/comment path: `docs(media): document aiostreams tailscale serve ownership`
- Route-owner split path: `refactor(system): centralize tailscale serve route ownership`

## Phase 8 — Mechanical Nix lint cleanup for feature modules

Audit finding addressed:

- F-008: unused lambda arguments and empty pattern noise.

Targets:

- Feature modules reported by `deadnix`.
- Non-generated modules with trivial `statix` warnings.

Known candidates from audit:

- `modules/features/desktop/fcitx5.nix`
- `modules/features/desktop/waypaper.nix`
- `modules/features/system/docker.nix`
- `modules/features/system/maintenance.nix`
- `modules/features/media/aiostreams.nix`
- Any remaining `theme-zen.nix` warning after Phase 1.

Changes:

- Remove unused lambda args.
- Replace unused `overrideAttrs` args with `_`/`_old` as appropriate.
- Replace empty `{ ... }:` with `_:` only in simple non-generated modules where it improves readability.
- Avoid touching generated `hardware-configuration.nix` files only for style.

Validation:

```bash
nix run --no-write-lock-file nixpkgs#deadnix -- --fail modules/features modules/desktops || true
for target in modules/features modules/desktops; do
  nix run --no-write-lock-file nixpkgs#statix -- check "$target" || true
done
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
```

Expected result:

- `deadnix` warnings for planned feature modules are gone or explicitly documented.
- Any remaining statix warnings are either generated-file noise or separately tracked.

Commit target:

- `chore(nix): remove feature-module lint noise`

## Phase 9 — Docs sync, full validation, and final report update

Targets:

- `docs/for-agents/001-repo-map.md`
- this plan, if execution notes are needed before archival
- optionally a short completion log under `docs/for-agents/current/` if implementation spans multiple sessions.

Changes:

- Update repo map if owner names or feature-private helper files changed.
- Update the audit report only if a finding's conclusion materially changes, or create a short completion note instead.
- Keep historical archive docs intact.

Mandatory validation:

```bash
./scripts/check-docs-drift.sh
./scripts/run-validation-gates.sh all
./scripts/check-repo-public-safety.sh
```

Mandatory Nix gates:

```bash
nix flake metadata
nix eval path:$PWD#nixosConfigurations.predator.config.system.stateVersion
nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.stateVersion
nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.$(source scripts/lib/common.sh; source scripts/lib/nix_eval.sh; enter_repo_root scripts/run-validation-gates.sh; nix_eval_sole_hm_user_for_host predator).home.path
nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel
```

Additional host evals for touched server/board phases:

```bash
nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath
nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath
```

Closure diff if runtime-affecting package behavior changed:

```bash
nix build path:$PWD#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-nix-pattern-tidy
nix run nixpkgs#nvd -- diff /tmp/predator-hyprland-only /tmp/predator-nix-pattern-tidy
```

Commit target:

- `docs(agents): close nix pattern tidy remediation`

Archive step after completion:

- Move this plan to `docs/for-agents/archive/plans/`.
- Move any corresponding progress log to `docs/for-agents/archive/log-tracks/`.

## Risk matrix

| Risk | Phase | Mitigation |
|------|-------|------------|
| Theme refactor changes visible theme output | 1, 2 | Evaluate theme values and build HM before commit; do not change selected flavor/accent/icon name. |
| Local package set changes package closure unexpectedly | 3 | Use evaluated HM `pkgs`; run HM build and closure diff if needed. |
| Renaming Aurelius owners breaks host imports | 4 | Run publisher-name gate, config contracts, Aurelius eval. Keep behavior unchanged. |
| Cerebelo boot/board compatibility breaks | 5 | Prefer documentation unless a safe upstream-compatible replacement is proven; do not switch runtime without explicit approval. |
| Tailscale Serve route reset removes unrelated routes | 7 | Search for other tracked routes first; document single-owner assumption or centralize routes before behavior change. |
| Lint cleanup churns generated hardware files | 8 | Exclude generated hardware configs from style-only cleanup. |
| Incidental flake input update | Any | Use `--no-write-lock-file` where possible; inspect and restore `flake.lock` drift. |

## Rollback

Code rollback:

```bash
git revert <bad-commit>
```

Branch rollback if a safety tag was created:

```bash
git reset --hard pre-nix-pattern-tidy
```

Runtime rollback if a later switch causes issues:

```bash
sudo nixos-rebuild switch --rollback
```

For Cerebelo-specific runtime risk, do not proceed to runtime application without a separate explicit recovery plan.

## Definition of Done

- Findings F-001 through F-008 are either fixed or explicitly documented as accepted exceptions with rationale.
- No new role/selector/context framework is introduced.
- No private files are read or referenced.
- `flake.lock` is unchanged unless a separately approved input update occurs.
- `./scripts/run-validation-gates.sh all` passes.
- `./scripts/check-repo-public-safety.sh` passes.
- Mandatory predator eval/build gates pass.
- Aurelius/Cerebelo evals pass for phases that touch their owner surfaces.
- Active docs remain small; completed plan/logtrack are archived at the end.
