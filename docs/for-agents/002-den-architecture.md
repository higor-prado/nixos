# Den Architecture

This document is historical context only.

The tracked repo no longer has an active `den` runtime or any tracked `.nix`
code that depends on `den`. Canonical outputs come from the repo-local
dendritic runtime
(`repo.hosts.*`, `repo.users.*`, `flake.modules.*`, and
`configurations.nixos.*.module`).

When this document conflicts with the active runtime, the dendritic runtime
wins. Use this file only to understand older commits, archived migration logs,
or historical design decisions.

## What den provided

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

## Historical aspect pattern in this repo

Every tracked feature file under `modules/features/` defines exactly one aspect.
Category subfolders are fine; den auto-discovers recursively. Features with
only NixOS config use a single `.nixos` class. User-owned aspects can also use
plain `.homeManager`:

```nix
{ ... }:
{
  den.aspects.my-feature = {
    nixos = { config, lib, pkgs, ... }: {
      # NixOS-only config (services, packages, etc.)
    };
    homeManager = { pkgs, ... }: {
      # User-owned HM config — den routes this to home-manager.users.<userName>
      programs.foo.enable = true;
    };
  };
}
```

The aspect name (e.g. `my-feature`) is used in host `includes` lists.

## Home-manager integration

### Den-native `.homeManager` class for user-owned config

`vic/den` natively provides a `.homeManager` class on any aspect. When a host
registers a user with `classes = [ "homeManager" ]`, den's context pipeline
automatically routes the user aspect's `homeManager` attribute to
`home-manager.users.<userName>`.

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
integration module, which does two things when a host has users with
`classes = [ "homeManager" ]`:
- extends `den.schema.host` with the `home-manager.enable` and `home-manager.module` options
- activates `den.ctx.hm-host` / `den.ctx.hm-user` so each user-context aspect's `.homeManager`
  class is forwarded into `home-manager.users.<userName>`

### Host-owned Home Manager is explicit mutual routing

In current `den`, the normal host pipeline is unidirectional:
- host-owned config runs in `den.ctx.host { host }`
- user-owned config runs in `den.ctx.user { host, user }`
- Home Manager is just another forwarded user class

That means a host aspect's plain top-level `.homeManager` does **not** reach
host users automatically. For host-owned HM config, the correct model is:

1. enable `den._.mutual-provider` in the user context
2. declare host-to-user config through `provides.to-users` or `provides.<user>`
3. aggregate those projections at the host aspect's `_.to-users` surface

Example feature:

```nix
{ ... }:
{
  den.aspects.git-gh = {
    provides.to-users.homeManager = { ... }: {
      programs.git.enable = true;
      programs.gh.enable = true;
    };
  };
}
```

Example host aggregation:

```nix
{ den, ... }:
{
  den.aspects.predator = {
    includes = with den.aspects; [
      git-gh
      fish
    ];

    _.to-users.includes = with den.aspects; [
      git-gh._.to-users
      fish._.to-users
    ];
  };
}
```

This split is intentional:
- `provides.to-users` is the public authoring API documented by `den`
- `_.to-users` is the internal namespace consumed by `den._.mutual-provider`
- host files own aggregation because they own composition

## Universal aspects — historical `den.default`

`den.default.includes` lists aspects that are injected into **every** host
unconditionally. This is the canonical mechanism for repo-wide invariants —
aspects that must be present regardless of host role.

Historically this lived in a dedicated `den-defaults` shim, which has since
been removed from the canonical path:

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

Server-specific policy used to live in a separate `server-base` shim with
mutable-users and SSH hardening defaults. That shim has been removed from the
canonical path.

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

Historically the schema was extended by a dedicated `den-host-context` shim:

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

Feature aspects that need host context use `den.lib.parametric` with `includes`
entries or explicit mutual-provider projections. Choose the correct shape based
on who owns the config:

```nix
# For nixos config that needs host.* — use perHost (fires only in {host} context):
den.aspects.my-feature = den.lib.parametric {
  includes = [
    (den.lib.perHost (
      { host }:
      {
        nixos = { ... }: {
          environment.systemPackages = [ host.customPkgs.foo ];
        };
      }
    ))
  ];
};

# For host-owned Home Manager config that needs host.* — use provides.to-users
# and let the host aggregate the resulting _.to-users surface:
den.aspects.my-feature = den.lib.parametric {
  provides.to-users = { host, ... }: {
    homeManager = { pkgs, ... }: {
      home.packages = host.llmAgents.homePackages;
    };
  };
};

# Host composition must aggregate the feature's mutual surface:
den.aspects.my-host._.to-users.includes = [
  den.aspects.my-feature._.to-users
];

# For config that needs BOTH host-level nixos AND host-owned homeManager — split ownership:
den.aspects.my-feature = den.lib.parametric {
  includes = [
    (den.lib.perHost ({ host }: { nixos.environment.systemPackages = host.customPkgs.tools; }))
  ];
  provides.to-users = { host, ... }: {
    homeManager.home.packages = host.customPkgs.extras;
  };
};
```

### Current dispatch rules

Current `den` is unidirectional by default. For host-owned feature code:

| Goal | Pattern |
|---|---|
| Only in host context (`{host}`) | `den.lib.perHost ({ host }: ...)` |
| Host-owned HM for all users on that host | `provides.to-users = { host, ... }: { homeManager = ...; }` |
| Host-owned HM for one specific user | `provides.<user> = { user, ... }: { homeManager = ...; }` |
| User-owned config for each host where the user exists | plain owned `.nixos` / `.homeManager` on the user aspect |

`den.lib.perHost` is already in use in this repo (fish.nix, ssh.nix, niri.nix).
Use it for any nixos-only include that accesses `host.*`. `den.lib.parametric`
is required whenever an aspect has context-dependent `includes` or captures
`host` data in `provides.to-users`.

> **Note on den source:** `~/git/den` may be behind the pinned flake.lock revision.
> Always use the nix store path or `nix flake metadata .` to find the authoritative pinned
> den source for API reference. The pinned source is in `/nix/store/<hash>-source/`.
> Example: `nix flake metadata . --json | jq -r '.locks.nodes.den.locked.narHash'`.

Owned `nixos`/`homeManager` attributes (not in `includes`) are routed by den's context
pipeline automatically and do not need these guards.

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
If the config belongs to the user regardless of host, keep it on the user
aspect's owned `.homeManager`. If it belongs to the host and should reach users,
route it explicitly through mutual routing instead of a plain host-owned
`.homeManager`.

## Self-contained feature imports

When a feature is parametric and captures `{ host, ... }`, it can declare its own
NixOS module imports inside the parametric nixos block. This makes the feature
self-contained — the host composition only lists the aspect name, not the
upstream NixOS module import:

```nix
den.aspects.my-feature = den.lib.parametric {
  includes = [
    (den.lib.perHost (
      { host }:
      {
        nixos = { ... }: {
          imports = [ host.inputs.upstream.nixosModules.default ];
          # feature config that depends on the imported module
        };
      }
    ))
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
