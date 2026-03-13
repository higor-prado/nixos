# Den Architecture

This repo uses [den](https://github.com/vic/den) as its NixOS module
framework. This document explains how den works in the context of this repo.

## What den provides

Den is a flake-parts module that offers:

1. **Auto-discovery**: all `*.nix` files under `modules/` are auto-imported.
   Files prefixed with `_` are skipped (used for helpers and data).

2. **Aspects**: named, composable NixOS module units declared as:
   ```nix
   den.aspects.<name>.nixos = { config, lib, ... }: { ... };
   ```

3. **Includes**: aspects can include other aspects:
   ```nix
   den.aspects.<name>.includes = with den.aspects; [ feature-a feature-b ];
   ```

4. **Host declaration**:
   ```nix
   den.hosts.x86_64-linux.<hostname> = { };
   ```
   This declares a nixosConfiguration entry for the host.

## Aspect pattern in this repo

Every tracked feature file under `modules/features/` defines exactly one aspect.
Category subfolders are fine; den auto-discovers recursively. Features with
only NixOS config use a single `.nixos` class; features with both NixOS and
home-manager config use both classes:

```nix
{ ... }:
{
  den.aspects.my-feature = {
    nixos = { config, lib, pkgs, ... }: {
      # NixOS-only config (services, packages, etc.)
    };
    homeManager = { pkgs, ... }: {
      # HM config — den routes this to home-manager.users.<userName> automatically
      programs.foo.enable = true;
    };
  };
}
```

The aspect name (e.g. `my-feature`) is used in host `includes` lists.

## Home-manager integration

### Den-native `.homeManager` class (target architecture)

`vic/den` natively provides a `.homeManager` class on any aspect. When a host
registers a user with `classes = [ "homeManager" ]`, den's context pipeline
automatically routes each aspect's `homeManager` attribute to
`home-manager.users.<userName>` for every matching user.

**User registration** (`modules/hosts/predator.nix`):
```nix
den.hosts.x86_64-linux.predator.users.higorprado.classes = [ "homeManager" ];
```

**User aspect** (`modules/users/higorprado.nix`):
```nix
{ den, ... }:
{
  den.aspects.higorprado = {
    includes = [
      den._.define-user         # name/home + HM username/homeDirectory
      den._.primary-user         # isNormalUser, wheel, networkmanager
      (den._.user-shell "fish")  # programs.fish.enable + shell at OS and HM level
    ];
    nixos = { ... }: {
      users.users.higorprado = {
        group = "higorprado";
      };
      users.groups.higorprado = { };
    };
    homeManager = { lib, ... }: {
      home.stateVersion = "25.11";
      imports = lib.optional (builtins.pathExists ../../private/higorprado.nix) ../../private/higorprado.nix;
    };
  };
}
```

In the live repo, `den._.define-user` now owns `name`, `home`,
`home.username`, and `home.homeDirectory`; the user aspect keeps only the
repo-specific primary group wiring plus HM state/imports.

Den's HM integration is currently provided by den's upstream Home Manager
integration module,
which does two things when a host has users with `classes = [ "homeManager" ]`:
- extends `den.schema.host` with the `home-manager.enable` and `home-manager.module` options
- activates `den.ctx.hm-host` / `den.ctx.hm-user` so each aspect's `.homeManager`
  class is forwarded into `home-manager.users.<userName>`

After the March 13, 2026 `den` change (`4bdcb63`), host-to-user OS reentry is
no longer implicit. If a host aspect needs to run again with `{ host, user }`
at the OS layer, that is now an explicit opt-in via `den._.bidirectional`.
Tracked repo features should prefer the narrowest correct context instead of
depending on bidirectional reentry by default.

## Host composition

A host aspect (`modules/hosts/<name>.nix`) declares which features the host
uses and wires the host-specific hardware config:

```nix
{ den, inputs, ... }:
{
  den.hosts.x86_64-linux.<name> = { };

  den.aspects.<name> = {
    includes = with den.aspects; [
      user-context
      host-contracts
      home-manager-settings
      system-base
      fish
      terminal
      editor-neovim
      desktop-dms-on-niri
    ];

    nixos = { lib, ... }: {
      config = { };
      imports = [
        ../../hardware/<name>/default.nix
      ];
    };
  };
}
```

## private/ directory

`private/` holds gitignored per-user home-manager overrides:
- `private/higorprado.nix` (gitignored) — entry point imported by `modules/users/higorprado.nix`
- `private/higorprado/` (gitignored) — modular private config (env, git, paths, ssh, theme-paths)
- `private/higorprado.nix.example` (tracked) — shows the expected shape

Generic helper functions used by tracked modules live under `lib/`, including:
- `lib/mutable-copy.nix` — utility for mutable config provisioning, used by features

## Host context propagation

Host context (`inputs`, `customPkgs`, semantic `llmAgents`) is propagated differently for NixOS and home-manager modules.

### Host context schema

The schema is extended via `modules/lib/den-host-context.nix`:

```nix
den.schema.host = { ... }: {
  options = {
    llmAgents = lib.mkOption {
      type = lib.types.submodule {
        options = {
          homePackages = lib.mkOption { type = lib.types.listOf lib.types.raw; default = [ ]; };
          systemPackages = lib.mkOption { type = lib.types.listOf lib.types.raw; default = [ ]; };
        };
      };
      default = { };
    };
    customPkgs = lib.mkOption { type = lib.types.raw; default = { }; };
    inputs = lib.mkOption { type = lib.types.raw; };
  };
};
```

### Setting host context

Host files set den-level context:

```nix
den.hosts.x86_64-linux.predator = {
  users.higorprado.classes = [ "homeManager" ];
  inherit inputs customPkgs llmAgents;
};
```

Feature aspects that need host context receive it through den parametric
includes:

```nix
den.aspects.my-feature = den.lib.parametric {
  includes = [
  ({ host, ... }: {
      nixos = { ... }: {
        environment.systemPackages = [ host.customPkgs.foo ];
      };
    })
  ];
}
```

For host-aware Home Manager config, use the same den parametric pattern:

```nix
den.aspects.my-feature = den.lib.parametric {
  includes = [
    ({ host, ... }: {
      homeManager = { ... }: {
        home.packages = host.llmAgents.homePackages;
      };
    })
  })
  ];
}
```

When host policy matters, prefer semantic host-owned selections over probing raw
package universes inside the feature. Example:

```nix
let
  llmAgentsPkgs = inputs.llm-agents.packages.${system} or { };
  llmAgents = {
    homePackages = with llmAgentsPkgs; [ claude-code codex ];
    systemPackages = [ ];
  };
in
{
  den.hosts.x86_64-linux.predator = {
    users.higorprado.classes = [ "homeManager" ];
    inherit inputs customPkgs llmAgents;
  };
}
```

If a Home Manager fragment also needs standard HM args (`config`, `lib`, `pkgs`), receive them inside the nested HM module function:

```nix
den.aspects.my-feature = den.lib.parametric {
  includes = [
    ({ host, ... }: {
      homeManager = { config, lib, pkgs, ... }: {
        # Use both host context and HM module args
      };
    })
  ];
}
```

Only use `{ host, user, ... }` when the fragment is genuinely user-specific.
If the HM config is generic across all HM users on the host and does not need
host data, prefer owned `homeManager = { ... }: { ... };` on the aspect.

## Module auto-discovery boundary

Den auto-discovers `modules/**/*.nix`. Files starting with `_` are excluded:
- `modules/features/shell/_starship-settings.nix` — starship config data

Never place option declarations outside `modules/features/` (checked by
`scripts/check-option-declaration-boundary.sh`).
