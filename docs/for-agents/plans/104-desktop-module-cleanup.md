# Desktop Module Cleanup

## Goal

Eliminate the last `packages-` prefix from the entire repo (`packages-fonts.nix` →
`fonts.nix`) and extract browsers from `desktop-apps.nix` into a dedicated
`browsers.nix` module. After this cleanup, all 6 feature categories reach naming
consistency with zero legacy prefixes.

## Scope

In scope:

- Rename `packages-fonts.nix` → `fonts.nix`
  - Update published module: `nixos.packages-fonts` → `nixos.fonts`
- Extract 4 browsers (Firefox, Chromium, Brave, Zen) from `desktop-apps.nix`
  into new `desktop/browsers.nix` → `homeManager.browsers`
- `desktop-apps.nix` retains: teams-for-linux, meld, obsidian, super-productivity
- Update host imports in `predator.nix` (only host that imports desktop modules)
- Update docs: `001-repo-map.md`, `003-module-ownership.md`

Out of scope:

- Changing any browser configuration or package versions
- Reorganizing other desktop modules
- Adding or removing packages
- Touching `_theme-catalog.nix` or `_papirus-tray-patched.nix` helpers

## Current State

### packages-fonts.nix — last `packages-` prefix in repo

```nix
flake.modules.nixos.packages-fonts = { pkgs, ... }: {
  fonts.packages = with pkgs; [ noto-fonts ... nerd-fonts.jetbrains-mono ... ];
};
```

Referenced in:

- `modules/hosts/predator.nix`: `nixos.packages-fonts`
- `docs/for-agents/001-repo-map.md`: `desktop/packages-fonts.nix — Nerd fonts`
- `docs/for-agents/003-module-ownership.md`: `modules/features/desktop/packages-fonts.nix — machine-wide fonts`

### desktop-apps.nix — mixed browsers + apps

```nix
flake.modules.homeManager.desktop-apps = { pkgs, config, ... }: {
  programs.firefox = { ... };    # browser
  programs.chromium = { ... };   # browser
  programs.brave = { ... };      # browser
  home.packages = [
    inputs.zen-browser...         # browser
    pkgs.teams-for-linux          # app
    pkgs.meld                     # app
    pkgs.obsidian                 # app
    pkgs.super-productivity       # app
  ];
};
```

### Host import

Only predator imports desktop modules. Aurelius and cerebelo are headless.

Predator current hmDesktop list includes: `homeManager.desktop-apps` (among 20+ others).
Predator current nixos list includes: `nixos.packages-fonts`.

## Desired End State

### fonts.nix — clean name

```nix
# modules/features/desktop/fonts.nix
flake.modules.nixos.fonts = { pkgs, ... }: { fonts.packages = ...; };
```

### browsers.nix — new module

```nix
# modules/features/desktop/browsers.nix
flake.modules.homeManager.browsers = { inputs, pkgs, config, ... }: {
  programs.firefox = { ... };
  programs.chromium = { ... };
  programs.brave = { ... };
  home.packages = [ inputs.zen-browser... ];
};
```

### desktop-apps.nix — apps only

```nix
flake.modules.homeManager.desktop-apps = { pkgs, ... }: {
  home.packages = [ pkgs.teams-for-linux pkgs.meld pkgs.obsidian pkgs.super-productivity ];
};
```

### Predator imports

```diff
 nixos:
-  nixos.packages-fonts
+  nixos.fonts

 homeManager hmDesktop:
   homeManager.desktop-apps
+  homeManager.browsers
```

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval` predator
- `git status` — confirm clean

### Phase 1: Rename `packages-fonts.nix` → `fonts.nix`

Targets:

- `modules/features/desktop/packages-fonts.nix` → `fonts.nix`

Changes:

- `git mv packages-fonts.nix fonts.nix`
- Update `flake.modules.nixos.packages-fonts` → `flake.modules.nixos.fonts`

Validation:

- `git status` — rename tracked
- Published name matches filename

Commit target:

- `refactor(desktop): rename packages-fonts to fonts`

### Phase 2: Create `browsers.nix` from `desktop-apps.nix`

Targets:

- NEW: `modules/features/desktop/browsers.nix`
- `modules/features/desktop/desktop-apps.nix`

Changes:

- Create `browsers.nix` publishing `homeManager.browsers`
- Move Firefox, Chromium, Brave, Zen from `desktop-apps.nix`
- `desktop-apps.nix` retains teams-for-linux, meld, obsidian, super-productivity
- `browsers.nix` captures `inputs` flake arg (for Zen) in outer lambda

Validation:

- Verify `browsers.nix` content matches extracted browsers
- Verify `desktop-apps.nix` has only the 4 productivity apps
- `nix eval` predator — module auto-imported

Commit target:

- `refactor(desktop): extract browsers from desktop-apps into browsers module`

### Phase 3: Update predator host imports

Targets:

- `modules/hosts/predator.nix`

Changes:

- `nixos.packages-fonts` → `nixos.fonts`
- Add `homeManager.browsers` to `hmDesktop` list (alongside `homeManager.desktop-apps`)

Validation:

- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- Verify browsers (firefox, chromium, brave, zen) present in HM derivation
- Verify fonts (noto, jetbrains-mono, etc.) present in NixOS font packages

Commit target:

- `refactor(predator): update imports for desktop module cleanup`

### Phase 4: Update docs

Targets:

- `docs/for-agents/001-repo-map.md`
- `docs/for-agents/003-module-ownership.md`

Changes (001-repo-map.md):

```diff
-- `desktop/packages-fonts.nix` — Nerd fonts
+- `desktop/fonts.nix` — system fonts (noto, fira, jetbrains, nerd-fonts)
+- `desktop/browsers.nix` — browsers (Firefox, Chromium, Brave, Zen)
```

Changes (003-module-ownership.md):

```diff
-- `modules/features/desktop/packages-fonts.nix` — machine-wide fonts
+- `modules/features/desktop/fonts.nix` — machine-wide fonts
```

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`

Commit target:

- `docs: update repo map and ownership for desktop cleanup`

### Phase 5: Final validation

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `nix eval` predator
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `grep -rn "packages-fonts" modules/` — must return nothing
- `grep -rn "packages-fonts" docs/for-agents/001-repo-map.md docs/for-agents/003-module-ownership.md` — must return nothing
- `grep -rn "packages-" modules/` — must return nothing (zero `packages-` prefixes in entire repo)
- `ls modules/features/desktop/` — 23 files (was 22, +browsers.nix, -packages-fonts.nix)

## Risks

- **`inputs` capture**: `browsers.nix` needs `inputs` in the outer lambda for `inputs.zen-browser`. Currently `desktop-apps.nix` also captures `inputs`. After extraction, `desktop-apps.nix` no longer needs `inputs` — simplify lambda.
- **Predator-only**: Both `packages-fonts` and `desktop-apps`/`browsers` are only imported by predator. No impact on aurelius or cerebelo.
- **Zen browser flake input**: The `inputs.zen-browser` reference moves from `desktop-apps.nix` to `browsers.nix`. The flake input exists at repo level — no change needed.

## Definition of Done

- [ ] `packages-fonts.nix` renamed to `fonts.nix`
- [ ] `browsers.nix` created with Firefox, Chromium, Brave, Zen
- [ ] `desktop-apps.nix` contains only productivity apps
- [ ] Predator imports updated
- [ ] Docs updated
- [ ] `nix eval` predator passes
- [ ] `nix build --no-link` predator (NixOS + HM) passes
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] Zero `packages-` prefixes anywhere in `modules/`
- [ ] Zero stale references in living docs
- [ ] Desktop category: 23 files, all with consistent naming
