# Add a Feature (Den Aspect)

## 1. Create the feature file

Create a new file in `modules/features/<category>/` (for example `modules/features/shell/<name>.nix`).

Choose the pattern that matches your feature's needs:

### Pattern 1 — No host data needed (most features)

```nix
{ ... }:
{
  den.aspects.my-feature = {
    nixos = { config, lib, pkgs, ... }: {
      # NixOS-only config
    };
    homeManager = { pkgs, ... }: {
      # HM config — routed automatically to home-manager.users.<userName>
    };
  };
}
```

### Pattern 2 — Needs `host.*` (flake inputs, customPkgs, llmAgents)

For nixos config that reads host data — `den.lib.perHost` (fires once, in host pipeline only):

```nix
{ den, ... }:
{
  den.aspects.my-feature = den.lib.parametric {
    includes = [
      (den.lib.perHost (
        { host }:
        {
          nixos = { ... }: {
            imports = [ host.inputs.upstream.nixosModules.default ];
          };
        }
      ))
    ];
  };
}
```

For homeManager config that reads host data — `take.atLeast` with `{host,user}` (fires in user
pipeline only, never at bare host level):

```nix
{ den, ... }:
{
  den.aspects.my-feature = den.lib.parametric {
    includes = [
      (den.lib.take.atLeast (
        { host, user }:
        {
          homeManager = { pkgs, ... }: {
            home.packages = [ host.customPkgs.some-tool ];
          };
        }
      ))
    ];
  };
}
```

`den.lib.perUser` is the canonical alias for the homeManager case: `den.lib.perUser ({ host, user }: ...)` is equivalent to `take.atLeast` and more readable.

For both — split into two includes (see `modules/features/dev/llm-agents.nix`).

**Never** use bare `{ host, ... }:` or `{ host }:` inside `includes` — they fire in both
`{host}` and `{host,user}` contexts, duplicating config.

Notes:
- Use `.homeManager` directly. Do not use the retired `hasHomeManagerUsers` / `optionalAttrs` pattern.
- `den.lib.parametric` is required whenever an aspect has context-dependent `includes`.

## 2. Add to host includes

In `modules/hosts/<your-host>.nix`, add the aspect to the host's `includes` list:

```nix
includes = with den.aspects; [
  # ...
  my-feature
];
```

## 3. Declare options if needed

If the feature needs custom options, declare them in the feature file that owns them or in the narrow contract module that owns that concern.

## 4. Verify

```bash
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```
