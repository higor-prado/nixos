# Extensibility Contracts

## Adding a feature

1. Create `modules/features/<category>/<name>.nix` using the den aspect pattern
2. If the feature needs custom options, declare them in the feature owner or the narrow contract module that owns that concern
3. Add to the host's `includes` list in `modules/hosts/<host>.nix`
4. Verify with `./scripts/check-extension-contracts.sh`

### Feature patterns

**NixOS-only feature:**
```nix
{ den, ... }:
{
  den.aspects.my-feature = den.lib.parametric {
    includes = [
      ({ host, ... }: {
        nixos = { ... }: {
          environment.systemPackages = [ host.customPkgs.foo ];
        };
      })
    ];
  };
}
```

**Feature with home-manager:**
```nix
{ den, ... }:
{
  den.aspects.my-feature = den.lib.parametric {
    includes = [
      ({ host, user, ... }: {
        nixos = { ... }: {
          # NixOS config
        };
        homeManager = { ... }: {
          home.packages = host.llmAgents.homePackages;
        };
      })
    ];
  };
}
```

When a feature needs host-specific package choice, prefer semantic host data
like `host.llmAgents.homePackages` or `host.desktopPackages.niri` over probing
host identity or raw package-set universes inside the shared feature.

If you need both host context and HM module args (`config`, `lib`, `pkgs`):
```nix
homeManager = { config, lib, pkgs, ... }: {
  # Use both host context captured by the parametric include and HM args
};
```
**Do not use `extraSpecialArgs`** — use den parametric includes for host-aware logic.

## Adding a desktop composition

1. Create `modules/desktops/<name>.nix` with aspect name `desktop-<name>`
2. The file declares `den.aspects.desktop-<name>` with:
   - `nixos` class: composition-specific greetd/portal baseline and any composition parameters (e.g. `custom.niri.standaloneSession`)
   - `homeManager` class: provision composition-specific mutable config and any user-scoped systemd drop-ins owned by the composition
3. Add to a host's includes list alongside the individual feature aspects it composes
4. Verify with `./scripts/check-desktop-composition-matrix.sh`

See `modules/desktops/dms-on-niri.nix` and `modules/desktops/niri-standalone.nix` for reference. Baseline duplication across composition files is intentional per den philosophy (lesson 40).

## Adding a host

See [workflow: add a host](../for-humans/workflows/103-add-host.md).

Required files:
- `hardware/host-descriptors.nix`: descriptor entry
- `hardware/<name>/default.nix`: hardware imports + runtime role
- `modules/hosts/<name>.nix`: den aspect with includes + system wiring

## Extension contracts enforced by scripts

- Desktop host must include a `desktop-*` composition aspect
- `hardware/host-descriptors.nix` must stay script-only (`integrations` only)
- `hardware/<name>/default.nix` must expose `custom.host.role`
- `modules/hosts/<name>.nix` must declare at least one tracked host user under `den.hosts.<system>.<name>.users`
- No `environment.systemPackages` in host default.nix
- No `openssh.authorizedKeys.keys` in tracked host files
