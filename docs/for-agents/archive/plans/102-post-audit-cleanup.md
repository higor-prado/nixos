# Post-Audit Cleanup (Report 2026-04-30)

## Goal

Apply all actionable fixes from the comprehensive repo audit, except the
two items explicitly kept: Firefox profile `y4loqr0b.default` (theme
management) and the `linuwu-sense`/`linuwu_sense` naming (avoid breakage).

## Scope

In scope:
- Remove dead `homeManager.rofi` from skeleton script and test fixture
- Update skeleton desktop imports to reflect current stack
- Uniformize module publishing style (block → dotted-path) for 10 modules
- Remove dead browser/terminal title suffixes from `active-window.sh`
- Archive plan 101 (already executed)
- Add missing modules to `001-repo-map.md`
- Fix inaccurate htop/logid descriptions in `001-repo-map.md`

Out of scope:
- Firefox profile path `y4loqr0b.default` — kept intentionally
- `linuwu-sense` naming — kept to avoid breakage
- Any behavioral changes to NixOS/HM configs
- Reordering imports or changing host compositions

## Current State

- Validation gates pass (13/13)
- Public safety check passes
- No stale references to removed apps in active `.nix`, `.lua`, `.css`, `.toml`
- 10 feature modules use block syntax: `flake.modules = { nixos.X = ...; }`
- 60+ feature modules use dotted-path syntax: `flake.modules.nixos.X = ...`
- `new-host-skeleton.sh` and fixture still reference `homeManager.rofi`
- `active-window.sh` has dead suffix patterns for Vivaldi, Floorp, Google Chrome
- Plan 101 (remove-terminals-browsers) executed but not archived
- 7 modules missing from repo map

## Desired End State

- Zero references to `homeManager.rofi` in tracked, non-archive files
- Skeleton generates valid imports for the current desktop stack
- All feature modules use the same dotted-path publishing style
- `active-window.sh` only strips suffixes for installed browsers
- Plan 101 archived; plan 102 is the only active plan in `plans/`
- `001-repo-map.md` lists all existing modules
- `001-repo-map.md` accurately describes htop and logid provisioning

## Phases

### Phase 1: Archive plan 101

Plan 101 was executed in commit `3ee8a28`. Move it to archive.

Targets:
- `docs/for-agents/plans/101-remove-terminals-browsers.md`

Changes:
- Move to `docs/for-agents/archive/plans/101-remove-terminals-browsers.md`

Validation:
- `./scripts/run-validation-gates.sh structure` (docs-drift check)

Commit target:
- `chore(agents): archive plan 101 (terminals/browsers removal executed)`

---

### Phase 2: Fix skeleton script — remove rofi, add walker

Targets:
- `scripts/new-host-skeleton.sh:52`

Changes:
- Replace `homeManager.rofi` with `homeManager.walker`

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`

Commit target:
- `fix(scripts): replace dead homeManager.rofi with homeManager.walker in skeleton`

---

### Phase 3: Fix test fixture — remove rofi, add walker + theme

Targets:
- `tests/fixtures/new-host-skeleton/desktop/modules/hosts/zeus.nix`

Changes:
- Replace `homeManager.rofi` with `homeManager.walker`
- Add `homeManager.theme-base` and `homeManager.theme-zen` (complementary
  to the Walker stack and essential for desktop theming)

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`

Commit target:
- `fix(tests): update zeus fixture imports (rofi→walker, add theme modules)`

---

### Phase 4: Update skeleton desktop imports

Add modules introduced after the skeleton was created that are part of the
standard Hyprland desktop stack.

Targets:
- `scripts/new-host-skeleton.sh` — `desktop_imports_for` function

Changes (NixOS additions):
```diff
         nixos.desktop-hyprland-standalone
         nixos.regreet
         nixos.hyprland
+        nixos.fcitx5
+        nixos.packages-fonts
         nixos.nix-cache-settings
```

Changes (Home Manager additions — applied on top of Phase 2):
```diff
         homeManager.desktop-hyprland-standalone
         homeManager.desktop-viewers
         homeManager.hyprland
+        homeManager.fcitx5
         homeManager.mako
         homeManager.qt-theme
-        homeManager.rofi
+        homeManager.walker
         homeManager.session-applets
+        homeManager.theme-base
+        homeManager.theme-zen
         homeManager.waybar
         homeManager.wayland-tools
```

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- Generate a throw-away skeleton and verify it does not reference missing modules

Commit target:
- `feat(scripts): modernize skeleton desktop imports for hyprland-standalone`

---

### Phase 5: Uniformize module publishing style (block → dotted-path)

Convert the 10 modules that use the block syntax to the canonical
dotted-path syntax prescribed by `002-architecture.md`.

Files to convert:
- `modules/features/system/docker.nix`
- `modules/features/system/mosh.nix`
- `modules/features/system/podman.nix`
- `modules/features/system/packages-server-tools.nix`
- `modules/features/desktop/nautilus.nix`
- `modules/features/desktop/fcitx5.nix`
- `modules/features/desktop/gaming.nix`
- `modules/features/desktop/hyprland.nix`
- `modules/features/dev/editor-neovim.nix`
- `modules/desktops/hyprland-standalone.nix`

Pattern — before:
```nix
{
  flake.modules = {
    nixos.foo = { ... }: { ... };
    homeManager.foo = { ... }: { ... };
  };
}
```

Pattern — after:
```nix
{
  flake.modules.nixos.foo = { ... }: { ... };
  flake.modules.homeManager.foo = { ... }: { ... };
}
```

Note: This is a pure syntax transform — no semantic change. Both forms
evaluate to the same attrset because there are no `mkIf`/`mkMerge`
conditionals wrapping the block.

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`

Diff expectation:
- Zero diff in evaluated `toplevel.drvPath` for all three hosts
- No change in `flake.modules.*` surface

Commit target:
- `refactor: uniformize module publishing style to dotted-path syntax`

---

### Phase 6: Clean dead browser title suffixes in active-window.sh

Targets:
- `config/apps/waybar/scripts/active-window.sh`

Changes:
- Remove Vivaldi, Floorp, and Google Chrome entries from
  `strip_browser_title()` (6 lines: lines 28–33)

Before:
```bash
    " — Vivaldi" \
    " - Vivaldi" \
    ...
    " — Floorp" \
    " - Floorp" \
    ...
    " — Google Chrome" \
    " - Google Chrome" \
```

After: remove those 6 lines.

Validation:
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `chore(waybar): remove dead browser title suffixes from active-window.sh`

---

### Phase 7: Update repo map — missing modules

Targets:
- `docs/for-agents/001-repo-map.md`

Changes (add to System section):
```
- `system/attic-client.nix` — Attic client HM package + substituter docs
- `system/attic-publisher.nix` — Attic post-build-hook publisher (predator, cerebelo)
- `system/forgejo.nix` — Forgejo Git service (aurelius only)
- `system/grafana.nix` — Grafana dashboard (aurelius only)
- `system/mosh.nix` — Mosh UDP firewall rules + user package
- `system/node-exporter.nix` — Prometheus node exporter (aurelius only)
- `system/prometheus.nix` — Prometheus server (aurelius only)
```

Also fix htop and logid descriptions:

Before:
```
- `config/apps/htop/` — tracked htoprc provisioned by copy-once
- `config/apps/logid/` — tracked LogiOps config provisioned by copy-once
```

After:
```
- `config/apps/htop/` — tracked htoprc provisioned via `builtins.path` to `xdg.configFile`
- `config/apps/logid/` — tracked LogiOps config provisioned via `environment.etc`
```

Validation:
- `./scripts/run-validation-gates.sh structure` (docs-drift check)
- Manual review: all listed paths exist

Commit target:
- `docs(repo-map): add missing modules, fix htop/logid provisioning descriptions`

---

## Risks

- **Phase 4 (skeleton imports):** Adding `nixos.fcitx5` imports the fcitx5
  NixOS module which sets `i18n.inputMethod.type = "fcitx5"`. This is
  desirable for desktop hosts but worth noting — it's an opinionated
  default.
- **Phase 5 (publishing style):** Syntax-only change, no semantic risk.
  Modules that publish both NixOS and HM in one block become two separate
  attribute paths — functionally identical to the previous block form.

## Definition of Done

- [ ] Plan 101 archived in `docs/for-agents/archive/plans/`
- [ ] Zero references to `homeManager.rofi` in tracked non-archive files
- [ ] `new-host-skeleton.sh` generates valid imports
- [ ] Test fixture `zeus.nix` has correct imports
- [ ] All 10 modules use dotted-path syntax
- [ ] `active-window.sh` has no dead browser/terminal suffixes
- [ ] `001-repo-map.md` lists attic-client, attic-publisher, forgejo,
      grafana, mosh, node-exporter, prometheus
- [ ] htop and logid descriptions corrected in repo map
- [ ] All validation gates pass
- [ ] `nix eval .#nixosConfigurations.{predator,aurelius,cerebelo}.config.system.build.toplevel.drvPath` unchanged from baseline
