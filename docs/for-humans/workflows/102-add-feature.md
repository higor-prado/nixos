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

### Pattern 2 — Needs host data (`inputs`, `customPkgs`, `llmAgents`)

Read it from the runtime context inside the lower-level module:

```nix
{ ... }:
{
  flake.modules.nixos.my-feature = { config, ... }: {
    imports = [ config.repo.context.host.inputs.upstream.nixosModules.default ];
  };

  flake.modules.homeManager.my-feature = { config, ... }: {
    home.packages = [ config.repo.context.host.customPkgs.some-tool ];
  };
}
```

## 2. Add to host imports

In `modules/hosts/<your-host>.nix`, import the published lower-level modules:

```nix
imports = [
  config.flake.modules.nixos.my-feature
];

home-manager.users.${user.userName}.imports = [
  config.flake.modules.homeManager.my-feature
];
```

## 3. Declare options if needed

If the feature needs custom options, declare them in the feature file that owns them or in the narrow contract module that owns that concern.

## 4. Verify

```bash
./scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```
