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
  configurations.nixos.ci-runner.module =
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
        nixos.ssh
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
          homeManager.ssh
        ];
      };
    };
}
