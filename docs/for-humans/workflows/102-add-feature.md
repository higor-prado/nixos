# Add a Feature (Den Aspect)

## 1. Create the feature file

Create a new file in `modules/features/<category>/` (for example `modules/features/shell/<name>.nix`).

Use the current den-native pattern:

```nix
{ den, ... }:
{
  den.aspects.my-feature = den.lib.parametric {
    includes = [
      ({ host, user, ... }: {
        nixos = { lib, pkgs, ... }: {
          # NixOS-level config here
          environment.systemPackages = [ host.customPkgs.some-tool ];
        };

        homeManager = { lib, pkgs, ... }: {
          # Optional Home Manager config here
          home.packages = host.llmAgents.homePackages;
        };
      })
    ];
  };
}
```

Notes:
- Use `.homeManager` directly. Do not use the retired `hasHomeManagerUsers` / `optionalAttrs` pattern.
- When a feature needs host-specific data, use a den parametric include and capture `{ host, ... }`.

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
