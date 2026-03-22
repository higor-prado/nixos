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
  configurations.nixos.aurelius.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;

      nixosInfrastructure = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
      ];
      nixosCoreServices = [
        nixos.attic-server
        nixos.attic-local-publisher
        nixos.networking
        nixos.docker
        nixos.forgejo
        nixos.github-runner
        nixos.mosh
        nixos.node-exporter
        nixos.prometheus
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.tailscale
        nixos.fish
        nixos.ssh
      ];
      nixosUserTools = [
        nixos.higorprado
        nixos.editor-neovim
        nixos.packages-toolchains
        nixos.packages-server-tools
        nixos.packages-system-tools
      ];

      hmUserTools = [
        homeManager.higorprado
        homeManager.core-user-packages
        homeManager.docker
        homeManager.git-gh
        homeManager.monitoring-tools
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.starship
        homeManager.terminal-tmux
        homeManager.tui-tools
      ];
      hmDev = [
        homeManager.dev-devenv
        homeManager.dev-tools
        homeManager.editor-neovim
        homeManager.packages-toolchains
      ];
    in
    {
      imports = nixosInfrastructure ++ nixosCoreServices ++ nixosUserTools ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager = {
        users.${userName} = {
          imports = hmUserTools ++ hmShell ++ hmDev;

          programs.fish.shellAbbrs = {
            naui = "nh os info";
            nausi = "nh os info";
            naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
            nauc = "nh clean all";
            nauct = "systemctl status nh-clean.timer --no-pager";
          };
        };
      };
    };
}
