# Hyprland Cleanup Review and Nix Pattern Audit

Date: 2026-04-27
Branch: `cleanup/hyprland-only`
Base reviewed against: `pre-hyprland-only-cleanup`

## Scope

This report covers three tidy-up goals:

1. Review the Hyprland-only cleanup that was just executed.
2. Archive plans/log tracks that are no longer active.
3. Audit tracked Nix code for places that appear to drift from the repo philosophy and coding pattern.

No private override contents were read. The audit covered tracked public Nix surfaces under `flake.nix`, `modules/`, `hardware/`, `lib/`, and `pkgs/`.

## Inputs and checks used

Manual/document review:

- `docs/for-agents/000-operating-rules.md`
- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/002-architecture.md`
- `docs/for-agents/003-module-ownership.md`
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/006-extensibility.md`
- `docs/for-agents/999-lessons-learned.md`
- `docs/for-humans/01-philosophy.md`

Repository review commands:

```bash
git diff --stat pre-hyprland-only-cleanup..HEAD
git diff --name-status pre-hyprland-only-cleanup..HEAD
git log --oneline pre-hyprland-only-cleanup..HEAD
find flake.nix modules hardware lib pkgs -name '*.nix' -type f | wc -l
rg -n 'specialArgs|extraSpecialArgs|repo\.context|\{ *host *\}:|\{ *hostName *\}:' flake.nix modules hardware lib pkgs -g '*.nix'
rg -n 'mkIf' modules hardware lib pkgs flake.nix -g '*.nix'
rg -n '^\s*imports\s*=' modules/features modules/desktops -g '*.nix'
rg -n '_module\.args|specialArgs|extraSpecialArgs' flake.nix modules hardware lib pkgs -g '*.nix'
rg -n 'predator|aurelius|cerebelo' modules/features modules/desktops -g '*.nix'
rg -n 'environment\.systemPackages|home\.packages' modules hardware lib pkgs flake.nix -g '*.nix'
nix run --no-write-lock-file nixpkgs#deadnix -- --fail flake.nix modules hardware lib pkgs
nix run --no-write-lock-file nixpkgs#statix -- check <target>
```

Existing validation status from the cleanup execution:

- `./scripts/run-validation-gates.sh all` passed at final cleanup HEAD.
- `./scripts/check-repo-public-safety.sh` passed at final cleanup HEAD.
- closure diff against `/tmp/predator-hyprland-before-cleanup` was small and consistent with dormant-source cleanup.

## Part 1 — Review of the Hyprland-only cleanup

### What changed

The cleanup branch contains these commits after `pre-hyprland-only-cleanup`:

```text
413cc82 refactor(hosts): make predator hyprland-only
7668ce3 refactor(desktop): remove niri dms and noctalia surfaces
2dc111f chore(lock): prune removed desktop inputs
82ac308 test(desktop): narrow desktop checks to hyprland
3e672b4 docs(desktop): document hyprland-only runtime
925e5d1 chore(docs): archive completed hyprland cleanup docs
```

Net diff reviewed:

- 40 files changed.
- 217 insertions.
- 2273 deletions.
- old Niri/DMS/Noctalia source surfaces were removed.
- `predator` now composes a single Hyprland desktop path.
- scripts, tests, and fixtures now model `hyprland-standalone` only.

### Cleanup quality assessment

Result: **good**.

Positive findings:

- Rollback path was preserved with tags:
  - `pre-hyprland-migration`
  - `pre-hyprland-only-cleanup`
- Work was split into coherent commits.
- `flake.nix` and `flake.lock` were pruned for removed desktop inputs instead of leaving dead pins.
- Active Nix/script/test surfaces no longer reference Niri/DMS/Noctalia.
- The host composition stayed explicit and dendritic; no selector booleans or generic desktop framework were introduced.
- Hyprland version/pin was not changed.
- The previous idle-lock/DPMS hotfix remained intact.

Minor cleanup note:

- An incidental `flake.lock` update to `home-manager` was produced during later audit commands and was restored before continuing. No unintended input update is part of this report work.

### Post-review active legacy-reference scan

The bounded living-source scan for old desktop names returned no active references after moving completed docs to archive:

```bash
rg -n -i 'niri|dms|noctalia|dms-awww|DankMaterialShell' \
  README.md AGENTS.md docs/for-agents/[0-9][0-9][0-9]-*.md \
  docs/for-agents/plans docs/for-agents/current docs/for-humans \
  scripts tests modules hardware config pkgs flake.nix \
  --glob '!docs/for-agents/archive/**'
```

Expected result: no output.

## Part 2 — Active plan/log-track tidy-up

Archived as completed/inactive:

- `docs/for-agents/plans/081-hyprland-app-parity-and-theme-coherence.md`
- `docs/for-agents/current/081-hyprland-app-parity-and-theme-coherence-progress.md`
- `docs/for-agents/plans/082-fcitx5-disable-clipboard-addon.md`
- `docs/for-agents/plans/083-hyprland-portal-backend-completeness.md`
- `docs/for-agents/plans/084-predator-responsiveness-scheduler-fix.md`

Left active intentionally:

- `docs/for-agents/plans/085-hyprland-session-service-ordering.md`

Reason: plan 085 still records runtime acceptance/application work that was blocked by lack of an interactive privileged switch. It should stay active until runtime validation after `nh os switch` + Hyprland relogin/reboot is confirmed, or until a human explicitly decides to archive it as historical.

Additional living-doc tidy-up:

- `docs/for-agents/001-repo-map.md` still mentioned removed `hardware/predator/packages.nix`; that stale living-doc entry was corrected during this pass.

## Part 3 — Nix code pattern audit

### Summary

No critical architecture break was found.

Strong positive findings:

- No `specialArgs` / `extraSpecialArgs` plumbing was found.
- No `repo.context` carrier pattern was found.
- No role/desktop selector booleans were found in active Nix code.
- No `mkIf` role/context checks were found; the scan found no `mkIf` occurrences in tracked Nix under the audited paths.
- All non-underscore files under `modules/features/**/*.nix` publish at least one `flake.modules.*` lower-level module.
- Option declarations remain within allowed owner surfaces according to the repository gate model.
- `hardware/<host>/default.nix` files are still thin machine entries and do not contain package bundles.

The findings below are therefore maintainability/pattern-alignment issues rather than immediate build blockers.

## Findings

### F-001 — Zen theme owner duplicates Catppuccin flavor/accent instead of using the shared theme catalog

Severity: **medium**

File:

- `modules/features/desktop/theme-zen.nix`

Evidence:

- The module hardcodes:
  - `flavor = "mocha"`
  - `accent = "lavender"`
- The repo already has the shared theme owner data in:
  - `modules/features/desktop/_theme-catalog.nix`
- `theme-base.nix` and `regreet.nix` consume the catalog, but `theme-zen.nix` does not.

Why this matters:

- This violates the repo philosophy of one source of truth.
- If the shared Catppuccin flavor/accent changes, Zen can silently drift from GTK/ReGreet/session theme.
- `deadnix` also reported `config` as unused in this module, which is a small symptom that the module is not deriving theme state from the normal theme path.

Recommended fix:

- Import `_theme-catalog.nix` in `theme-zen.nix` and derive `flavor`/`accent` from it.
- Keep only Zen-specific path construction in `theme-zen.nix`.
- Remove unused lambda arguments after the change.

Suggested slice:

```text
refactor(theme): make zen theme consume shared theme catalog
```

### F-002 — Host-specific Aurelius identity is embedded in generically named feature modules

Severity: **medium**

Files:

- `modules/features/system/github-runner.nix`
- `modules/features/system/attic-server.nix`
- `modules/features/system/attic-local-publisher.nix`

Evidence:

- `github-runner.nix` hardcodes paths/service names/labels around `aurelius`.
- `attic-server.nix` and `attic-local-publisher.nix` hardcode the cache name `aurelius` and descriptions mentioning Aurelius.

Why this matters:

- The modules live under `modules/features/system/` and are named as reusable capabilities, but part of their concrete identity is host-specific.
- The architecture says reusable behavior belongs in feature modules, while concrete host composition and host-specific operator wiring belong in host owners.
- This is not an immediate correctness bug because these modules are only imported by the intended host, but the naming/placement makes future reuse ambiguous.

Recommended fix options:

1. If these are intentionally Aurelius-only owners, rename them to make that true in the public API, e.g. `aurelius-github-runner`, `aurelius-attic-server`, `aurelius-attic-local-publisher`.
2. If they are meant to be reusable features, move the concrete host/cache/runner identity into a narrow option owner or into the importing host module, while keeping service behavior in the feature.

Preferred repo-philosophy fix:

- Use host inclusion as the condition, but make owner names match the real capability. Avoid generic names that conceal concrete host identity.

### F-003 — Predator host imports custom package set through a separate nixpkgs instantiation

Severity: **medium**

File:

- `modules/hosts/predator.nix`

Evidence:

- Top-level host `let` creates:
  - `system = "x86_64-linux"`
  - `customPkgs = import ../../pkgs { pkgs = import inputs.nixpkgs { inherit system; config.allowUnfree = true; }; inherit inputs; }`
- Later, inside the Home Manager user module, it uses `customPkgs.predator-tui` while also receiving the evaluated HM `pkgs` argument.

Why this matters:

- It creates a second `nixpkgs` instantiation that can drift from the actual host/HM `pkgs` instance.
- It repeats `allowUnfree` policy locally even though nixpkgs policy belongs in dedicated policy features.
- It makes the host module do package-set construction that can be derived from the existing lower-level `pkgs` argument.

Recommended fix:

- Move `customPkgs = import ../../pkgs { inherit pkgs inputs; };` into the HM user lambda where `pkgs` is already available.
- Remove the separate `inputs.nixpkgs` import from `modules/hosts/predator.nix`.

Suggested slice:

```text
refactor(hosts): derive predator custom packages from evaluated pkgs
```

### F-004 — Cerebelo host uses `_module.args` as an upstream board compatibility bridge

Severity: **medium-low**

File:

- `modules/hosts/cerebelo.nix`

Evidence:

- The host module sets:
  - `_module.args.rk3588 = { ... }`
  - `_module.args.nixos-generators = null`

Why this matters:

- The repo explicitly avoids `specialArgs`/`extraSpecialArgs` and carrier-style module plumbing.
- `_module.args` is not the same CLI/API mechanism, and this usage appears to be an upstream compatibility shim, but it still creates implicit module arguments outside the main dendritic surfaces.

Recommended fix:

- Treat this as a documented exception if the upstream RK3588 module requires it.
- Prefer moving the compatibility bridge closer to `hardware/cerebelo/board.nix` if it can be scoped there without breaking evaluation.
- If upstream now exposes proper options, replace `_module.args` with those options.

Suggested slice:

```text
chore(cerebelo): document rk3588 module-args exception
```

or, if removable:

```text
refactor(cerebelo): remove rk3588 module-args bridge
```

### F-005 — Theme catalog owns substantial icon-patching build logic

Severity: **medium-low**

File:

- `modules/features/desktop/_theme-catalog.nix`

Evidence:

- `_theme-catalog.nix` is documented as shared Catppuccin theme constants.
- It now includes a `pkgs.runCommand` derivation that copies and patches Papirus SVG assets for Waybar tray behavior.

Why this matters:

- The file name and docs imply data/catalog ownership, but it now owns non-trivial package build behavior.
- This makes the theme catalog harder to reason about and can blur ownership between theme constants, package derivation, and Waybar-specific tray fixes.

Recommended fix:

- Keep `_theme-catalog.nix` focused on shared constants and package references.
- Move the patched icon derivation to a narrow helper such as:
  - `modules/features/desktop/_papirus-tray-patched.nix`, or
  - `pkgs/papirus-tray-patched.nix` if it should be reusable package code.
- Have `_theme-catalog.nix` reference the resulting derivation.

Suggested slice:

```text
refactor(theme): split patched tray icon derivation from theme catalog
```

### F-006 — Music client feature hides an external Home Manager module import inside the lower-level module

Severity: **low-medium**

File:

- `modules/features/desktop/music-client.nix`

Evidence:

- The lower-level HM module imports:
  - `inputs.spicetify-nix.homeManagerModules.spicetify`

Why this matters:

- Capturing direct flake inputs inside a feature owner is an accepted repo pattern.
- However, importing a major external HM module inside a lower-level feature means the host composition does not visibly import that upstream module even though it materially shapes the user config.
- Lesson 30 says major upstream imports that materially shape a host should stay explicit in host composition.

Recommended fix:

- Decide whether `spicetify-nix` is an implementation detail of `music-client` or a major upstream import that should be visible in host composition.
- If strict explicitness is desired, publish a repo-owned top-level module wrapper for the upstream import, or add an explicit host import pattern with documentation.
- If keeping as-is, document that `music-client` owns the whole Spotify/Spicetify stack and the external import is intentionally encapsulated.

### F-007 — `aiostreams` feature is operationally host-specific despite generic feature naming

Severity: **low-medium**

File:

- `modules/features/media/aiostreams.nix`

Evidence:

- The module hardcodes:
  - local data path and env-file path;
  - port `3002`;
  - `tailscale serve reset` before serving this one app.

Why this matters:

- This is acceptable if the repo owns the entire host-level Tailscale Serve state for the importing machine.
- It is risky if other Tailscale Serve routes are ever added elsewhere: `tailscale serve reset` is global and can erase out-of-module state.
- The module reads as a reusable feature, but operationally it encodes a concrete deployment shape.

Recommended fix:

- Keep as-is only if this module is the single source of truth for Tailscale Serve on that host.
- Otherwise, make Tailscale Serve route ownership explicit in a dedicated host/server feature, or avoid global reset when composing multiple routes.

### F-008 — Small lint/style drift: unused lambda arguments and empty `{ ... }` patterns

Severity: **low**

Evidence from `deadnix`:

- `modules/features/desktop/theme-zen.nix`: unused `config`
- `modules/features/desktop/fcitx5.nix`: unused `pkgs` in HM module
- `modules/features/desktop/waypaper.nix`: unused `old` in `overrideAttrs`
- `modules/features/system/docker.nix`: unused `pkgs` in NixOS module
- `modules/features/system/maintenance.nix`: unused `pkgs`
- `modules/features/media/aiostreams.nix`: unused `config` and `lib`

Evidence from `statix`:

- Several modules use empty `{ ... }:` patterns where `_:` would be cleaner.
- Several generated/hardware files use repeated dotted keys. This is mostly style, especially for hardware-configuration files.

Why this matters:

- These do not violate the dendritic architecture.
- Cleaning them improves readability and reduces false signals in future audits.

Recommended fix:

- Make a mechanical lint cleanup slice for non-generated feature files first.
- Do not churn `hardware-configuration.nix` files solely for statix style unless there is a stronger reason.

Suggested slice:

```text
chore(nix): remove unused lambda arguments in feature modules
```

## Recommended remediation order

1. **Theme source-of-truth fix**: F-001, then optionally F-005.
2. **Predator package-set cleanup**: F-003.
3. **Aurelius/server naming clarification**: F-002.
4. **Cerebelo `_module.args` exception/removal decision**: F-004.
5. **External import visibility decision for Spicetify**: F-006.
6. **AIOStreams operational ownership clarification**: F-007.
7. **Mechanical lint cleanup**: F-008.

## Suggested next plans

If executing fixes document-driven, split into small plans/slices:

1. `088-theme-source-of-truth-cleanup.md`
   - F-001 and F-005.
2. `089-host-package-and-server-owner-cleanup.md`
   - F-002 and F-003.
3. `090-cerebelo-rk3588-args-review.md`
   - F-004 only, because boot/board changes deserve isolation.
4. `091-nix-lint-mechanical-cleanup.md`
   - F-008 only.

## Conclusion

The Hyprland-only cleanup itself is structurally sound and aligned with the repo philosophy. The remaining Nix issues are mostly pre-existing maintainability/ownership clarity items surfaced by the audit. The most philosophy-relevant code issue is theme source duplication in `theme-zen.nix`; the most architecture-relevant item is the small set of generic feature owners that encode concrete Aurelius identity.
