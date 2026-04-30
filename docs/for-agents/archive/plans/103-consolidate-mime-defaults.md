# Consolidate MIME Defaults into Single Owner Module

## Goal

Consolidate all `xdg.mimeApps` configuration from `desktop-apps.nix` and
`desktop-viewers.nix` into a new canonical owner `desktop/mime-defaults.nix`,
eliminating duplication and fragmentation. Zero regression guaranteed via
byte-identical `nix eval` diff.

## Scope

In scope:
- Create `modules/features/desktop/mime-defaults.nix` with all MIME rules
- Add to predator host imports
- Remove `xdg.mimeApps` blocks from `desktop-apps.nix` and `desktop-viewers.nix`
- Remove the now-unused `nonFirefoxWebHandlers` lists from both
- Validate byte-identical MIME output before and after

Out of scope:
- Changing any MIME rule values (pure consolidation)
- Removing the `associations.added`-vs-`defaultApplications` redundancy
- Touching nautilus.nix (it owns directory MIME independently)
- Any other module changes

## Current State

Three modules contribute to `xdg.mimeApps` on predator:

| Module | `defaultApplications` | `associations.added` | `associations.removed` |
|---|---|---|---|
| `desktop-apps.nix` | web (5 types) + json (1) | web (4 types) | web (4 types): Brave, Chromium, Zen |
| `desktop-viewers.nix` | image (8) + pdf (2) | image (8) + pdf (2) | image+pdf (10 types): Brave, Firefox |
| `nautilus.nix` | directory (2) | — | — |

Observations:
- `desktop-apps.nix` and `desktop-viewers.nix` each maintain a list named
  `nonFirefoxWebHandlers` with different meanings and different contents.
- `associations.added` entries for web/img/pdf mirror their
  `defaultApplications` entries — redundant by XDG spec, but preserved for
  zero-diff guarantee.
- `nautilus.nix` is NOT in scope — it independently owns directory MIME.

## Baseline (captured before any changes)

```bash
nix eval --json \
  path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.mimeApps
```

Result saved to `/tmp/mime-baseline.json`. The post-change eval must produce
identical JSON (key order may vary; validate with `jq --sort-keys` diff).

## Desired End State

- `modules/features/desktop/mime-defaults.nix` exists — publishes `flake.modules.homeManager.mime-defaults`
- `modules/hosts/predator.nix` imports `homeManager.mime-defaults`
- `desktop-apps.nix` has zero `xdg.mimeApps` configuration
- `desktop-viewers.nix` has zero `xdg.mimeApps` configuration
- `nix eval` output is byte-identical to baseline

## Phases

### Phase 0: Capture baseline

```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.mimeApps \
  | jq --sort-keys > /tmp/mime-baseline.json
```

Validation:
- `jq` exits 0
- File is non-empty, contains valid JSON

---

### Phase 1: Create `mime-defaults.nix`

Targets:
- `modules/features/desktop/mime-defaults.nix` (new file)

Content: union of MIME rules from both modules, preserving exact values:

```nix
{ ... }:
{
  flake.modules.homeManager.mime-defaults =
    { ... }:
    let
      # Browsers to remove from web MIME associations.
      nonFirefoxWebHandlers = [
        "brave-browser.desktop"
        "com.brave.Browser.desktop"
        "chromium-browser.desktop"
        "zen.desktop"
      ];

      # Browsers to remove from image/PDF MIME associations
      # (so dedicated viewers take priority).
      browsersFromMediaHandlers = [
        "brave-browser.desktop"
        "firefox.desktop"
      ];

      imageMimeTypes = [
        "image/jpeg"
        "image/png"
        "image/gif"
        "image/webp"
        "image/avif"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
      ];

      pdfMimeTypes = [
        "application/pdf"
        "application/x-pdf"
      ];

      webMimeTypes = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      mkMimeMap =
        mimeTypes: desktopIds:
        builtins.listToAttrs (
          map (mime: {
            name = mime;
            value = if builtins.isList desktopIds then desktopIds else [ desktopIds ];
          }) mimeTypes
        );
    in
    {
      xdg.mimeApps = {
        defaultApplications =
          (mkMimeMap webMimeTypes "firefox.desktop")
          // (mkMimeMap imageMimeTypes "org.gnome.Loupe.desktop")
          // (mkMimeMap pdfMimeTypes "org.gnome.Papers.desktop")
          // {
            "x-scheme-handler/about" = [ "firefox.desktop" ];
            "x-scheme-handler/unknown" = [ "firefox.desktop" ];
            "application/json" = [ "code.desktop" ];
          };

        associations.added =
          (mkMimeMap webMimeTypes "firefox.desktop")
          // (mkMimeMap imageMimeTypes "org.gnome.Loupe.desktop")
          // (mkMimeMap pdfMimeTypes "org.gnome.Papers.desktop");

        associations.removed =
          (mkMimeMap webMimeTypes nonFirefoxWebHandlers)
          // (mkMimeMap imageMimeTypes browsersFromMediaHandlers)
          // (mkMimeMap pdfMimeTypes browsersFromMediaHandlers);
      };
    };
}
```

Validation:
- `./scripts/check-extension-contracts.sh`
- File compiles: `nix-instantiate --parse modules/features/desktop/mime-defaults.nix`

---

### Phase 2: Add `homeManager.mime-defaults` to predator

Targets:
- `modules/hosts/predator.nix` — `hmDesktop` list

Change: add `homeManager.mime-defaults` to `hmDesktop` list, adjacent to
`homeManager.desktop-apps` and `homeManager.desktop-viewers`.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`

---

### Phase 3: Remove MIME blocks from source modules

Targets:
- `modules/features/desktop/desktop-apps.nix`
- `modules/features/desktop/desktop-viewers.nix`

Changes in `desktop-apps.nix`:
- Remove entire `xdg.mimeApps` block
- Remove `nonFirefoxWebHandlers` let-binding (line 5-9)
- Module now owns only: browsers (Firefox, Chromium, Brave, Zen) + desktop apps (Teams, Meld, Obsidian, Super Productivity)

Changes in `desktop-viewers.nix`:
- Remove entire `xdg.mimeApps` block
- Remove `loupeDesktop`, `papersDesktop`, `braveDesktop` let-bindings
- Remove `imageMimeTypes`, `pdfMimeTypes`, `nonFirefoxWebHandlers`, `mkMimeMap` let-bindings
- Module now owns only: Loupe and Papers packages

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval path:$PWD#nixosConfigurations.cerebelo.config.system.build.toplevel.drvPath`

---

### Phase 4: Regression validation — byte-identical MIME output

```bash
nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.mimeApps \
  | jq --sort-keys > /tmp/mime-after.json

diff /tmp/mime-baseline.json /tmp/mime-after.json
```

**Exit code must be 0 (zero diff).** Any difference is a regression and must
be root-caused before proceeding.

Additional checks:
- `./scripts/run-validation-gates.sh structure`
- Verify `homeManager.mime-defaults` appears in `check-feature-publisher-name-match` output
- Verify no stale imports remain (aurelius/cerebelo don't import mime-defaults — correct, they don't need desktop MIME)

---

### Phase 5: Docs update

Targets:
- `docs/for-agents/001-repo-map.md`

Add under Desktop section:
```
- `desktop/mime-defaults.nix` — canonical owner of `xdg.mimeApps` defaults (web, image, PDF)
```

Update `desktop-apps.nix` and `desktop-viewers.nix` descriptions to note MIME moved out.

Validation:
- `./scripts/run-validation-gates.sh structure` (docs-drift check)

Commit target:
- `refactor(desktop): consolidate MIME defaults into mime-defaults.nix`

## Risks

- **Nix attrset merge ordering**: `defaultApplications` and `associations`
  are merged via `mkMerge` across modules. The new module's keys must not
  conflict with nautilus.nix keys. Verified: nautilus owns only
  `inode/directory` and `application/x-gnome-saved-search` — disjoint from
  web/image/PDF types.
- **Aurelius/Cerebelo**: Neither host imports `desktop-apps.nix` or
  `desktop-viewers.nix`. Adding `mime-defaults.nix` to predator only —
  zero impact on server hosts.

## Definition of Done

- [ ] `mime-defaults.nix` created with all MIME rules from both modules
- [ ] `homeManager.mime-defaults` imported in predator `hmDesktop`
- [ ] `desktop-apps.nix` has zero `xdg.mimeApps` configuration
- [ ] `desktop-viewers.nix` has zero `xdg.mimeApps` configuration
- [ ] `diff /tmp/mime-baseline.json /tmp/mime-after.json` is empty (zero diff)
- [ ] All three hosts eval successfully
- [ ] All validation gates pass
- [ ] Repo map updated
