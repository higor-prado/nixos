# Add a New Host

## 1. Generate skeleton

```bash
scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-experience]
```

This creates:
- `hardware/<host-name>/default.nix`
- `modules/hosts/<host-name>.nix`

## 2. Add descriptor

Add to `hardware/host-descriptors.nix`:

```nix
<host-name> = {
  integrations = {
    disko = true;
    homeManager = true;
  };
};
```

## 3. Create host module

The generated `modules/hosts/<host-name>.nix` already uses the current dendritic runtime shape:

```nix
{ inputs, config, ... }:
let
  hostName = "<host-name>";
  hardwareImports = [
    ../../hardware/<host-name>/default.nix
  ];
in
{
  repo.hosts.<host-name> = {
    system = "x86_64-linux";
    role = "desktop";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.<host-name>.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      hostInventory = config.repo.hosts.${hostName};
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.repo-runtime-contracts
        nixos.system-base
        # ... add lower-level nixos modules here
      ] ++ hardwareImports;

      custom = {
        host.role = hostInventory.role;
        user.name = userName;
      };

      home-manager.users.${userName}.imports = [
        homeManager.higorprado
        # ... add lower-level homeManager modules here
      ];
    };
}
```

`repo.hosts.<host-name>.trackedUsers` is the tracked inventory contract for users on that host.
Keep hardware import lists and other runtime-only payload local to the host file
instead of storing them under `repo.hosts.<host-name>`.

If a feature needs host-owned semantic selections, declare those directly in
the host or derive them directly from the owner's captured inputs. Example:

```nix
{
  repo.hosts.<host-name> = {
    trackedUsers = [ "higorprado" ];
  };
}
```

Keep runtime-only payload local to the host file. Example:

```nix
let
  llmAgentsHomePackages = with inputs.llm-agents.packages.${system}; [
    claude-code
    codex
  ];
in {
  home-manager.users.${userName}.home.packages = llmAgentsHomePackages;
}
```

## 4. Add hardware config

Add hardware files under `hardware/<host-name>/`:
- `hardware-configuration.nix` (nixos-generate-config output)
- `disko.nix` (disk layout, if using disko)
- `hardware/` split files (GPU, laptop, encryption, etc.)
- keep `custom.host.role = "desktop"` or `"server"` in `hardware/<host-name>/default.nix`

## 5. Verify

```bash
git add hardware/<host-name>/default.nix modules/hosts/<host-name>.nix
nix eval path:$PWD#nixosConfigurations.<host-name>.config.system.build.toplevel.drvPath
./scripts/run-validation-gates.sh structure
```
