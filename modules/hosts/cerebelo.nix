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
        nixos.attic-client
      ];
      nixosCoreServices = [
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.tailscale
        nixos.fish
        nixos.ssh
        nixos.mosh
      ];
      nixosUserTools = [
        nixos.higorprado
        nixos.editor-neovim
        nixos.packages-server-tools
        nixos.packages-system-tools
      ];

      hmUserTools = [
        homeManager.higorprado
        homeManager.core-user-packages
        homeManager.git-gh
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.starship
        homeManager.terminal-tmux
        homeManager.tui-tools
      ];
      hmDev = [
        homeManager.dev-tools
        homeManager.editor-neovim
      ];
    in
    {
      imports = nixosInfrastructure ++ nixosCoreServices ++ nixosUserTools ++ hardwareImports;

      _module.args.rk3588 = { inherit pkgsKernel; nixpkgs = upstreamNixpkgs; };
      # dtb-install.nix in the core module requires this in its function
      # signature but does not use it on extlinux systems.
      _module.args.nixos-generators = null;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = hmUserTools ++ hmShell ++ hmDev;

        programs.fish.shellAbbrs = {
          ncbi  = "nh os info";
          ncbsi = "nh os info";
          ncbst = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
          ncbc  = "nh clean all";
          ncbct = "systemctl status nh-clean.timer --no-pager";
        };
      };
    };
}
