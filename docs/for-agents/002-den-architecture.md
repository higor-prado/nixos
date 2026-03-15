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
      imports =
        lib.optional (builtins.pathExists ../../private/users/higorprado/default.nix)
          ../../private/users/higorprado/default.nix;
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

## Universal aspects — `den.default`

`den.default.includes` lists aspects that are injected into **every** host
unconditionally. This is the canonical mechanism for repo-wide invariants —
aspects that must be present regardless of host role.

Declared in `modules/features/core/den-defaults.nix`:

```nix
{ den, ... }:
{
  den.default.includes = with den.aspects; [
    den._.hostname
    user-context
    host-contracts
    system-base
    networking
    security
    keyboard
    nixpkgs-settings
    nix-settings
    maintenance
    tailscale
  ];
}
```

Host files must not re-list these. Only host-specific or role-specific aspects
belong in the host's own `includes`.

## Host composition

A host aspect (`modules/hosts/<name>.nix`) declares which features the host
uses and wires the host-specific hardware config. Universal aspects arrive via
`den.default` and must not be repeated:

```nix
{ den, inputs, ... }:
{
  den.hosts.x86_64-linux.<name> = { };

  den.aspects.<name> = {
    includes = with den.aspects; [
      # Only host-specific aspects here.
      # Universal aspects (hostname, networking, security, …) come from den.default.
      home-manager-settings
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

Server hosts add `server-base` to their includes for server-specific policy
(mutableUsers, no autologin, no documentation, SSH hardening).

## private/ directory

`private/` is the unified root for gitignored private overrides:
- `private/users/higorprado/default.nix.example` (tracked) — shape for the user-private entry point imported by `modules/users/higorprado.nix`
- `private/users/higorprado/*.nix.example` (tracked) — shapes for modular user-private config (env, git, paths, ssh, theme-paths)
- `private/hosts/predator/default.nix.example` and `private/hosts/aurelius/default.nix.example` (tracked) — shapes for the host-private entry points imported by the corresponding hardware owners
- `private/hosts/predator/auth.nix.example` (tracked) — shape for the optional predator host-private auth override
- the real gitignored files use the same paths without the `.example` suffix

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

Feature aspects that need host context should usually stay as plain aspect
attrsets and receive host context through parametric `includes` entries:

```nix
den.aspects.my-feature = {
  includes = [
    ({ host, ... }: {
      nixos = { ... }: {
        environment.systemPackages = [ host.customPkgs.foo ];
      };
    })
  ];
};
```

For host-aware Home Manager config, use the same shape:

```nix
den.aspects.my-feature = {
  includes = [
    ({ host, ... }: {
      homeManager = { ... }: {
        home.packages = host.llmAgents.homePackages;
      };
    })
  ];
};
```

Only reach for explicit `den.lib.parametric` wrappers when you need to tighten
dispatch semantics beyond the default aspect functor behavior.

When the host/user relationship is explicit rather than generic, prefer den
pair-routing through `provides` and batteries such as `den._.mutual-provider`
over host-name conditionals inside shared logic:

```nix
den.aspects.higorprado = {
  includes = [
    den._.mutual-provider
  ];

  provides.predator = { user, ... }: {
    nixos.users.users.${user.userName}.extraGroups = [ "linuwu_sense" ];
  };
};
```

For ordinary shared host-aware config, keep using parametric includes:

```nix
den.aspects.my-feature = {
  includes = [
    ({ host, ... }: {
      homeManager = { config, lib, pkgs, ... }: {
        # Use both host context and HM module args
      };
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

Only use `{ host, user, ... }` when the fragment is genuinely user-specific.
If the HM config is generic across all HM users on the host and does not need
host data, prefer owned `homeManager = { ... }: { ... };` on the aspect.

## Self-contained feature imports

When a feature is parametric and captures `{ host, ... }`, it can declare its own
NixOS module imports inside the parametric nixos block. This makes the feature
self-contained — the host composition only lists the aspect name, not the
upstream NixOS module import:

```nix
den.aspects.my-feature = den.lib.parametric {
  includes = [
    ({ host, ... }: {
      nixos = { ... }: {
        imports = [ host.inputs.upstream.nixosModules.default ];
        # feature config that depends on the imported module
      };
    })
  ];
};
```

Current examples: `modules/features/desktop/niri.nix`
(`host.inputs.niri.nixosModules.niri`),
`modules/features/desktop/dms.nix` (`host.inputs.dms.nixosModules.*`),
`modules/features/system/keyrs.nix`
(`host.inputs.keyrs.nixosModules.default`).

This keeps host files clean — `modules/hosts/<name>.nix` only lists aspect
names in `includes` and does not repeat upstream module imports that the
feature already owns.

## Module auto-discovery boundary

Den auto-discovers `modules/**/*.nix`. Files starting with `_` are excluded:
- `modules/features/shell/_starship-settings.nix` — starship config data

Never place option declarations outside `modules/features/` (checked by
`scripts/check-option-declaration-boundary.sh`).
