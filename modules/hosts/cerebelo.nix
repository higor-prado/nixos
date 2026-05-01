# Cerebelo host composition — Orange Pi 5 (RK3588S), headless server.
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  hostName = "cerebelo";
  upstreamNixpkgs = inputs.nixos-rk3588.inputs.nixpkgs;
  pkgsKernel = import upstreamNixpkgs { system = "aarch64-linux"; };
  hardwareImports = [
    inputs.nixos-rk3588.nixosModules.boards.orangepi5.core
    ../../hardware/cerebelo/default.nix
  ];
in
{
  configurations.nixos.cerebelo.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;

      nixosInfrastructure = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
        nixos.attic-publisher
      ];
      nixosCoreServices = [
        nixos.networking
        nixos.networking-resolved
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.tailscale
        nixos.fish
        nixos.ssh
        nixos.mosh
        nixos.podman
        nixos.aiostreams
      ];
      nixosUserTools = [
        nixos.higorprado
        nixos.editors-neovim
        nixos.server-tools
      ];

      hmUserTools = [
        homeManager.attic-client
        homeManager.higorprado
        homeManager.core-user-packages
        homeManager.git-gh
        homeManager.server-tools
        homeManager.podman
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.starship
        homeManager.tmux
        homeManager.tui-tools
      ];
      hmDev = [
        homeManager.editors-neovim
        homeManager.linters
      ];
    in
    {
      imports = nixosInfrastructure ++ nixosCoreServices ++ nixosUserTools ++ hardwareImports;

      # Upstream nixos-rk3588 board modules currently consume these module args.
      # Keep this as a narrow board-compatibility bridge for cerebelo only.
      # This is not a generic repo context pattern and should not be copied to
      # unrelated host/feature modules.
      _module.args.rk3588 = {
        inherit pkgsKernel;
        nixpkgs = upstreamNixpkgs;
      };
      # dtb-install.nix in the upstream core module requires this in its
      # function signature but does not use it on extlinux systems.
      _module.args.nixos-generators = null;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = hmUserTools ++ hmShell ++ hmDev;

        programs.fish.shellAbbrs = {
          ncu = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
          ncub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-cerebelo\"";
          ncut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-cerebelo\"";
          ncus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-cerebelo\"";
          ncui = "nh os info";
          ncust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
          ncuc = "nh clean all";
          ncuct = "systemctl status nh-clean.timer --no-pager";
        };
      };
    };
}
