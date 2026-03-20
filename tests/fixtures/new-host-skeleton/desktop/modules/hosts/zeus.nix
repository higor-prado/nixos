# zeus host composition - generated skeleton.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  hostName = "zeus";
  hardwareImports = [
    ../../hardware/zeus/default.nix
  ];
in
{
  repo.hosts.zeus = {
    inherit inputs customPkgs;
    role = "desktop";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.zeus.module =
    let
      host = config.repo.hosts.${hostName};
      user = config.repo.users.higorprado;
      repoContext = {
        inherit host;
        inherit hostName;
        inherit user;
        userName = user.userName;
      };
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        config.flake.modules.nixos.repo-runtime-contracts
        config.flake.modules.nixos.repo-context
        config.flake.modules.nixos.system-base
        config.flake.modules.nixos.home-manager-settings
        config.flake.modules.nixos.networking
        config.flake.modules.nixos.security
        config.flake.modules.nixos.keyboard
        config.flake.modules.nixos.nixpkgs-settings
        config.flake.modules.nixos.maintenance
        config.flake.modules.nixos.tailscale
        config.flake.modules.nixos.higorprado
        config.flake.modules.nixos.nix-settings
        config.flake.modules.nixos.packages-system-tools
        config.flake.modules.nixos.fish
        config.flake.modules.nixos.ssh
        host.inputs.niri.nixosModules.niri
        host.inputs.dms.nixosModules.dank-material-shell
        host.inputs.dms.nixosModules.greeter
        config.flake.modules.nixos.desktop-dms-on-niri
        config.flake.modules.nixos.dms
        config.flake.modules.nixos.niri
        config.flake.modules.nixos.xwayland
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = host.system;
      networking.hostName = hostName;

      custom = {
        host.role = host.role;
        user.name = user.userName;
      };

      home-manager.users.${user.userName} = {
        imports = [
          config.flake.modules.homeManager.repo-context
          config.flake.modules.homeManager.higorprado
          config.flake.modules.homeManager.core-user-packages
          config.flake.modules.homeManager.fish
          config.flake.modules.homeManager.git-gh
          config.flake.modules.homeManager.ssh
          config.flake.modules.homeManager.desktop-apps
          config.flake.modules.homeManager.desktop-base
          config.flake.modules.homeManager.desktop-dms-on-niri
          config.flake.modules.homeManager.desktop-viewers
          config.flake.modules.homeManager.dms
          config.flake.modules.homeManager.dms-wallpaper
          config.flake.modules.homeManager.niri
          config.flake.modules.homeManager.wayland-tools
        ];

        repo.context = repoContext;
      };

      repo.context = repoContext;
    };
}
