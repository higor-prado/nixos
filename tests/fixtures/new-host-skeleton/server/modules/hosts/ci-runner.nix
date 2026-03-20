# ci-runner host composition - generated skeleton.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  hostName = "ci-runner";
  hardwareImports = [
    ../../hardware/ci-runner/default.nix
  ];
in
{
  repo.hosts.ci-runner = {
    role = "server";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.ci-runner.module =
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

      home-manager.users.${userName} = {
        imports = [
          homeManager.higorprado
          homeManager.core-user-packages
          homeManager.fish
          homeManager.git-gh
          homeManager.ssh
        ];
      };
    };
}
