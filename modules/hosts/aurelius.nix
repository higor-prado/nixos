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
        nixos.aurelius-attic-server
        nixos.aurelius-attic-local-publisher
        nixos.networking
        nixos.docker
        nixos.docker-health-check
        nixos.forgejo
        nixos.grafana
        nixos.aurelius-github-runner
        nixos.mosh
        nixos.node-exporter
        nixos.prometheus
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.maintenance-disk-alert
        nixos.networking-wireguard-server
        nixos.tailscale
        nixos.fish
        nixos.ssh
      ];
      nixosUserTools = [
        nixos.higorprado
        nixos.editors-neovim
        nixos.server-tools
      ];

      hmUserTools = [
        homeManager.higorprado
        homeManager.core-user-packages
        homeManager.docker
        homeManager.git-gh
        homeManager.monitoring-tools
        homeManager.server-tools
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.starship
        homeManager.tmux
        homeManager.tui-tools
      ];
      hmDev = [
        homeManager.devenv
        homeManager.editors-neovim
        homeManager.linters
        homeManager.toolchains
      ];
    in
    {
      imports = nixosInfrastructure ++ nixosCoreServices ++ nixosUserTools ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      users.users.${userName}.extraGroups = [ "docker" ];

      home-manager = {
        users.${userName} = {
          imports = hmUserTools ++ hmShell ++ hmDev;

          programs.fish.shellAbbrs = {
            nau = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
            naub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-aurelius\"";
            naut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-aurelius\"";
            naus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-aurelius\"";
            naui = "nh os info";
            naust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
            nauc = "nh clean all";
            nauct = "systemctl status nh-clean.timer --no-pager";
          };
        };
      };
    };
}
