# Extensibility Contracts

## Adding a feature

1. Create `modules/features/<category>/<name>.nix` as a top-level dendritic module
2. Publish lower-level modules under `flake.modules.nixos.*` and/or `flake.modules.homeManager.*`
3. If the feature needs custom options, declare them in the feature owner or another narrow owner that genuinely owns that concern
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

**Host-aware feature — capture direct flake inputs in the owner and derive what the lower-level module needs locally:**
```nix
{ inputs, ... }:
{
  flake.modules.homeManager.my-feature =
    { pkgs, ... }:
    let
      customPkgs = import ../../../pkgs { inherit pkgs inputs; };
    in
    {
      home.packages = [ customPkgs.some-tool ];
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
  configurations.nixos.${hostName}.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.my-feature
      ];

      nixpkgs.hostPlatform = "x86_64-linux";
      networking.hostName = hostName;
      home-manager.users.${userName}.imports = [
        homeManager.higorprado
        homeManager.my-feature
      ];
    };
  };
}
```
**Do not use `specialArgs` or `extraSpecialArgs`** — publish values at the top level and consume them through narrow top-level facts, existing lower-level state, or `config.flake.modules.*`.

## Adding a desktop composition

1. Create `modules/desktops/<name>.nix`
2. Publish `flake.modules.nixos.desktop-<name>` and, if needed, `flake.modules.homeManager.desktop-<name>`
3. Add those published modules to the host's explicit NixOS/HM imports alongside the individual features they compose
4. Verify with `./scripts/check-desktop-composition-matrix.sh`

See `modules/desktops/dms-on-niri.nix` and `modules/desktops/niri-standalone.nix` for reference. Baseline duplication across composition files is intentional because each composition owns its own lower-level module payload.

## Adding a host

See [workflow: add a host](../for-humans/workflows/103-add-host.md).

Required files:
- `hardware/<name>/default.nix`: hardware imports + machine-owned defaults
- `modules/hosts/<name>.nix`: top-level host owner module plus `configurations.nixos.<name>.module`

## Extension contracts enforced by scripts

- Desktop host must include a `desktop-*` composition module
- Tracked hosts must have both `hardware/<name>/default.nix` and `modules/hosts/<name>.nix`
- No `environment.systemPackages` in host default.nix
- No `openssh.authorizedKeys.keys` in tracked host files
