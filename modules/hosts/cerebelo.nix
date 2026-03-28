# Cerebelo host composition — Orange Pi 5 (RK3588S), headless server.
{ inputs, config, ... }:
let
  system = "aarch64-linux";
  hostName = "cerebelo";
  hardwareImports = [
    ../../hardware/cerebelo/default.nix
  ];
in
{
  configurations.nixos.cerebelo.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
        nixos.rk3588-orangepi5
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.fish
        nixos.ssh
        nixos.mosh
        nixos.higorprado
        nixos.editor-neovim
        nixos.packages-server-tools
        nixos.packages-system-tools
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      home-manager.users.${userName} = {
        imports = [
          homeManager.higorprado
          homeManager.core-user-packages
          homeManager.git-gh
          homeManager.ssh
          homeManager.fish
          homeManager.starship
          homeManager.terminal-tmux
          homeManager.tui-tools
          homeManager.dev-tools
          homeManager.editor-neovim
        ];

        programs.fish.shellAbbrs = {
          ncbi = "nh os info";
          ncbst = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
          ncbc = "nh clean all";
        };
      };
    };
}
