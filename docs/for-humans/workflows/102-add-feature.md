# Add a Feature

## 1. Create the feature file

Create a new file in `modules/features/<category>/` (for example `modules/features/shell/<name>.nix`).

Publish the lower-level module(s) your feature owns.

### Pattern 1 — No host data needed (most features)

```nix
{ ... }:
{
  flake.modules.nixos.my-feature = { config, lib, pkgs, ... }: {
    # NixOS-only config
  };

  flake.modules.homeManager.my-feature = { pkgs, ... }: {
    # HM config
  };
}
```

### Pattern 2 — Rare case: truly owned semantic input

Declare a narrow feature-owned option only when the feature genuinely owns that
input:

```nix
{ lib, ... }:
{
  flake.modules.nixos.my-feature =
    { config, ... }:
    {
      options.custom.my-feature.package = lib.mkOption {
        type = lib.types.package;
      };

      config.environment.systemPackages = [ config.custom.my-feature.package ];
    };
}
```

If the host-specific part is just a local package selection or one-off runtime
payload, keep it in the host composition instead of inventing a repo-wide
carrier or broad option surface.

In this repo, this is the exception, not the default. Most feature files should
look like Pattern 1 and let host or desktop composition be the condition.

```nix
home-manager.users.${userName}.imports = [
  homeManager.my-feature
];
```

Avoid this:

```nix
{ ... }:
{
  flake.modules.nixos.my-feature = { config, ... }: {
    imports = [ config.repo.some-carrier.inputs.upstream.nixosModules.default ];
  };
}
```

## 2. Add to host imports

In `modules/hosts/<your-host>.nix`, import the published lower-level modules:

```nix
let
  inherit (config.flake.modules) homeManager nixos;
in
{
  imports = [
    nixos.my-feature
  ];

  home-manager.users.${userName}.imports = [
    homeManager.my-feature
  ];
}
```

## 3. Declare options only when the feature truly owns the fact

If the feature needs custom options, declare them in the feature file that owns them or in another narrow owner that genuinely owns that concern.

## 4. Verify

```bash
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```
