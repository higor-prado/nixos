# __HOST_NAME__ host composition - generated skeleton.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  hostName = "__HOST_NAME__";
  hardwareImports = [
    ../../hardware/__HOST_NAME__/default.nix
  ];
in
{
  configurations.nixos.__HOST_NAME__.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.nixpkgs-settings
        nixos.maintenance
        nixos.tailscale
        nixos.higorprado
        nixos.nix-settings
        nixos.server-tools
        nixos.fish
        nixos.ssh__NIXOS_DESKTOP_IMPORTS__
      ]
      ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = [
          homeManager.higorprado
          homeManager.core-user-packages
          homeManager.fish
          homeManager.git-gh
          homeManager.ssh__HOME_MANAGER_DESKTOP_IMPORTS__
        ];
      };
    };
}
