# ci-runner host composition - generated skeleton.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  hostName = "ci-runner";
  hardwareImports = [
    ../../hardware/ci-runner/default.nix
  ];
in
{
  repo.hosts.ci-runner = {
    inherit inputs customPkgs;
    role = "server";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.ci-runner.module =
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
        config.flake.modules.nixos.packages-server-tools
        config.flake.modules.nixos.packages-system-tools
        config.flake.modules.nixos.fish
        config.flake.modules.nixos.ssh
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
        ];

        repo.context = repoContext;
      };

      repo.context = repoContext;
    };
}
