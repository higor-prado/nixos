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
  configurations.nixos.<host-name>.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        # ... add lower-level nixos modules here
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = "x86_64-linux";
      networking.hostName = hostName;
      home-manager.users.${userName}.imports = [
        homeManager.higorprado
        # ... add lower-level homeManager modules here
      ];
    };
}
```

Keep hardware import lists and other runtime-only payload local to the host file.

If a feature needs host-owned semantic selections, declare those directly in
the host or derive them directly from the owner's captured inputs. Keep
runtime-only payload local to the host file. Example:

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

## 5. Verify

```bash
git add hardware/<host-name>/default.nix modules/hosts/<host-name>.nix
nix eval path:$PWD#nixosConfigurations.<host-name>.config.system.build.toplevel.drvPath
./scripts/run-validation-gates.sh structure
```
