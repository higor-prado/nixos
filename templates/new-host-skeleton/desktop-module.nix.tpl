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
  repo.hosts.__HOST_NAME__ = {
    role = "__HOST_ROLE__";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.__HOST_NAME__.module =
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
        nixos.home-manager-settings
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.nixpkgs-settings
        nixos.maintenance
        nixos.tailscale
        nixos.higorprado
        nixos.nix-settings
        nixos.packages-system-tools
        nixos.fish
        nixos.ssh__NIXOS_DESKTOP_IMPORTS__
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = hostInventory.system;
      networking.hostName = hostName;

      custom = {
        host.role = hostInventory.role;
        user.name = userName;
      };

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
