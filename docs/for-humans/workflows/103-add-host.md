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

The generated `modules/hosts/<host-name>.nix` already uses the current den-native shape:

```nix
{ den, inputs, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
in
{
  den.hosts.x86_64-linux.<host-name> = {
    users.higorprado = { };
    inherit inputs customPkgs;
  };

  den.aspects.<host-name> = {
    includes = with den.aspects; [
      den._.hostname
      user-context
      host-contracts
      system-base
      networking
      security
      keyboard
      nix-settings
      fish
      ssh
      terminal
      git-gh
      core-user-packages
      # ... add features as needed
    ];

    nixos = { ... }: {
      config = { };
      imports = [
        ../../hardware/<host-name>/default.nix
      ];
    };
  };
}
```

If the host should use den `.homeManager` aspects, add:

```nix
den.hosts.x86_64-linux.<host-name>.users.<user-aspect>.classes = [ "homeManager" ];
```

and include `home-manager-settings` in the host's `includes`.

If a feature needs host-owned semantic selections, declare those directly in
the host context. Example:

```nix
let
  llmAgentsPkgs = inputs.llm-agents.packages.${system} or { };
  llmAgents = {
    homePackages = with llmAgentsPkgs; [ claude-code codex ];
    systemPackages = [ ];
  };
in {
  den.hosts.x86_64-linux.<host-name> = {
    users.higorprado = { };
    inherit inputs customPkgs llmAgents;
  };
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
