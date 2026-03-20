# Extensibility Contracts

## Adding a feature

1. Create `modules/features/<category>/<name>.nix` as a top-level dendritic module
2. Publish lower-level modules under `flake.modules.nixos.*` and/or `flake.modules.homeManager.*`
3. If the feature needs custom options, declare them in the feature owner or the narrow contract module that owns that concern
4. Add the published lower-level modules to the host's explicit import lists in `modules/hosts/<host>.nix`
5. Verify with `./scripts/check-extension-contracts.sh`

### Feature patterns

**NixOS-only feature that needs no host data — publish a lower-level NixOS module:**
```nix
{ ... }:
{
  flake.modules.nixos.my-feature = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.some-tool ];
  };
}
```

**Host-aware feature — read host context from `repo.context.host` inside the lower-level module:**
```nix
{ ... }:
{
  flake.modules.homeManager.my-feature = { config, ... }: {
    home.packages = config.repo.context.host.customPkgs.extraPackages;
  };
}
```

**Host composition — declare one concrete configuration and import published modules explicitly:**
```nix
{ inputs, config, ... }:
let
  hostName = "my-host";
in
{
  repo.hosts.${hostName} = {
    system = "x86_64-linux";
    role = "desktop";
    trackedUsers = [ "higorprado" ];
    inherit inputs;
  };

  configurations.nixos.${hostName}.module =
    let
      host = config.repo.hosts.${hostName};
      user = config.repo.users.higorprado;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        config.flake.modules.nixos.repo-runtime-contracts
        config.flake.modules.nixos.repo-context
        config.flake.modules.nixos.system-base
        config.flake.modules.nixos.my-feature
      ];

      home-manager.users.${user.userName}.imports = [
        config.flake.modules.homeManager.repo-context
        config.flake.modules.homeManager.higorprado
        config.flake.modules.homeManager.my-feature
      ];

      repo.context = {
        inherit host;
        inherit hostName;
        inherit user;
        userName = user.userName;
      };

      home-manager.users.${user.userName}.repo.context = {
        inherit host;
        inherit hostName;
        inherit user;
        userName = user.userName;
      };
    };
  };
}
```
**Do not use `specialArgs` or `extraSpecialArgs`** — publish values at the top level and consume them through `config.repo.*` / `config.flake.modules.*`.

## Adding a desktop composition

1. Create `modules/desktops/<name>.nix`
2. Publish `flake.modules.nixos.desktop-<name>` and, if needed, `flake.modules.homeManager.desktop-<name>`
3. Add those published modules to the host's explicit NixOS/HM imports alongside the individual features they compose
4. Verify with `./scripts/check-desktop-composition-matrix.sh`

See `modules/desktops/dms-on-niri.nix` and `modules/desktops/niri-standalone.nix` for reference. Baseline duplication across composition files is intentional because each composition owns its own lower-level module payload.

## Adding a host

See [workflow: add a host](../for-humans/workflows/103-add-host.md).

Required files:
- `hardware/host-descriptors.nix`: descriptor entry
- `hardware/<name>/default.nix`: hardware imports + runtime role
- `modules/hosts/<name>.nix`: top-level host inventory entry plus `configurations.nixos.<name>.module`

## Extension contracts enforced by scripts

- Desktop host must include a `desktop-*` composition module
- `hardware/host-descriptors.nix` must stay script-only (`integrations` only)
- `hardware/<name>/default.nix` must expose `custom.host.role`
- `modules/hosts/<name>.nix` must declare at least one tracked host user under `repo.hosts.<name>.trackedUsers`
- No `environment.systemPackages` in host default.nix
- No `openssh.authorizedKeys.keys` in tracked host files
