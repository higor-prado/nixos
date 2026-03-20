# Aurelius host composition - server.
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  hostName = "aurelius";
in
{
  repo.hosts.aurelius = {
    inherit system inputs customPkgs;
    role = "server";
    trackedUsers = [ "higorprado" ];
    hardwareImports = [
      inputs.disko.nixosModules.disko
      ../../hardware/aurelius/default.nix
    ];
  };

  configurations.nixos.aurelius.module =
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
        config.flake.modules.nixos.home-manager-settings
        config.flake.modules.nixos.networking
        config.flake.modules.nixos.security
        config.flake.modules.nixos.keyboard
        config.flake.modules.nixos.nixpkgs-settings
        config.flake.modules.nixos.maintenance
        config.flake.modules.nixos.tailscale
        config.flake.modules.nixos.higorprado
        config.flake.modules.nixos.nix-settings
        config.flake.modules.nixos.packages-server-tools
        config.flake.modules.nixos.packages-system-tools
        config.flake.modules.nixos.fish
        config.flake.modules.nixos.ssh
      ] ++ host.hardwareImports;

      nixpkgs.hostPlatform = host.system;
      networking.hostName = hostName;

      custom = {
        host.role = host.role;
        user.name = user.userName;
      };

      home-manager = {
        users.${user.userName} = {
          imports = [
            config.flake.modules.homeManager.repo-context
            config.flake.modules.homeManager.higorprado
            config.flake.modules.homeManager.core-user-packages
            config.flake.modules.homeManager.fish
            config.flake.modules.homeManager.git-gh
            config.flake.modules.homeManager.ssh
          ];

          repo.context = {
            inherit host;
            inherit hostName;
            inherit user;
            userName = user.userName;
          };
        };
      };

      repo.context = {
        inherit host;
        inherit hostName;
        inherit user;
        userName = user.userName;
      };

      programs.fish.shellAbbrs = {
        naui = "nh os info";
        nausi = "nh os info";
        naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
        nauc = "nh clean all";
        nauct = "systemctl status nh-clean.timer --no-pager";
      };

      services.openssh.settings.KbdInteractiveAuthentication = false;
    };
}
