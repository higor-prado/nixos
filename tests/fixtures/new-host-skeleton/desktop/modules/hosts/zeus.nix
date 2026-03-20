# zeus host composition - generated skeleton.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  hostName = "zeus";
  hardwareImports = [
    ../../hardware/zeus/default.nix
  ];
in
{
  repo.hosts.zeus = {
    role = "desktop";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.zeus.module =
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
        nixos.ssh
        inputs.niri.nixosModules.niri
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms.nixosModules.greeter
        nixos.desktop-dms-on-niri
        nixos.dms
        nixos.niri
        nixos.xwayland
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
          homeManager.ssh
          homeManager.desktop-apps
          homeManager.desktop-base
          homeManager.desktop-dms-on-niri
          homeManager.desktop-viewers
          homeManager.dms
          homeManager.dms-wallpaper
          homeManager.niri
          homeManager.wayland-tools
        ];
      };
    };
}
