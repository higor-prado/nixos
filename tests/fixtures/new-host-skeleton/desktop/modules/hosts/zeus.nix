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
  configurations.nixos.zeus.module =
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
        nixos.packages-system-tools
        nixos.fish
        nixos.ssh
        inputs.hyprland.nixosModules.default
        nixos.desktop-hyprland-standalone
        nixos.regreet
        nixos.hyprland
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = [
          homeManager.higorprado
          homeManager.core-user-packages
          homeManager.fish
          homeManager.git-gh
          homeManager.ssh
          homeManager.desktop-apps
          homeManager.desktop-base
          homeManager.desktop-hyprland-standalone
          homeManager.desktop-viewers
          homeManager.hyprland
          homeManager.mako
          homeManager.qt-theme
          homeManager.rofi
          homeManager.satty
          homeManager.session-applets
          homeManager.waybar
          homeManager.wayland-tools
          homeManager.waypaper
          homeManager.wlogout
        ];
      };
    };
}
