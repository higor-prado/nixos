# Aurelius host composition - server.
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  hostName = "aurelius";
  hardwareImports = [
    inputs.disko.nixosModules.disko
    ../../hardware/aurelius/default.nix
  ];
in
{
  repo.hosts.aurelius = {
    inherit system;
    role = "server";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.aurelius.module =
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
        nixos.packages-server-tools
        nixos.packages-system-tools
        nixos.fish
        nixos.ssh
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = hostInventory.system;
      networking.hostName = hostName;

      custom = {
        host.role = hostInventory.role;
        user.name = userName;
      };

      home-manager = {
        users.${userName} = {
          imports = [
            homeManager.higorprado
            homeManager.core-user-packages
            homeManager.fish
            homeManager.git-gh
            homeManager.ssh
          ];
        };
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
