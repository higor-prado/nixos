# Predator host composition - desktop workstation.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  llmAgentsPkgs =
    inputs.llm-agents.packages.${system} or { };
  llmAgents = {
    homePackages = with llmAgentsPkgs; [
      claude-code
      codex
      crush
      kilocode-cli
      opencode
    ];
    systemPackages = [ ];
  };
  hostName = "predator";
in
{
  repo.hosts.predator = {
    inherit system inputs customPkgs llmAgents;
    role = "desktop";
    trackedUsers = [ "higorprado" ];
    hardwareImports = [
      inputs.disko.nixosModules.disko
      inputs.impermanence.nixosModules.impermanence
      ../../hardware/predator/default.nix
    ];
    extraSystemPackages = [ customPkgs.predator-tui ];
  };

  configurations.nixos.predator.module =
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
        config.flake.modules.nixos.audio
        config.flake.modules.nixos.gnome-keyring
        config.flake.modules.nixos.bluetooth
        host.inputs.niri.nixosModules.niri
        host.inputs.dms.nixosModules.dank-material-shell
        host.inputs.dms.nixosModules.greeter
        host.inputs.keyrs.nixosModules.default
        config.flake.modules.nixos.desktop-dms-on-niri
        config.flake.modules.nixos.dms
        config.flake.modules.nixos.maintenance-smartd
        config.flake.modules.nixos.networking-avahi
        config.flake.modules.nixos.networking-resolved
        config.flake.modules.nixos.niri
        config.flake.modules.nixos.nix-settings-desktop
        config.flake.modules.nixos.podman
        config.flake.modules.nixos.upower
        config.flake.modules.nixos.higorprado
        config.flake.modules.nixos.editor-neovim
        config.flake.modules.nixos.fcitx5
        config.flake.modules.nixos.gaming
        config.flake.modules.nixos.keyrs
        config.flake.modules.nixos.nix-settings
        config.flake.modules.nixos.nautilus
        config.flake.modules.nixos.packages-docs-tools
        config.flake.modules.nixos.packages-fonts
        config.flake.modules.nixos.packages-system-tools
        config.flake.modules.nixos.packages-toolchains
        config.flake.modules.nixos.docker
        config.flake.modules.nixos.fish
        config.flake.modules.nixos.llm-agents
        config.flake.modules.nixos.ssh
        config.flake.modules.nixos.xwayland
      ] ++ host.hardwareImports;

      nixpkgs.hostPlatform = host.system;
      networking.hostName = hostName;

      custom = {
        host.role = host.role;
        user.name = user.userName;
      };

      environment.systemPackages = host.extraSystemPackages;

      home-manager = {
        users.${user.userName} = {
          imports = [
            config.flake.modules.homeManager.repo-context
            config.flake.modules.homeManager.higorprado
            config.flake.modules.homeManager.backup-service
            config.flake.modules.homeManager.core-user-packages
            config.flake.modules.homeManager.desktop-apps
            config.flake.modules.homeManager.desktop-viewers
            config.flake.modules.homeManager.desktop-dms-on-niri
            config.flake.modules.homeManager.dms
            config.flake.modules.homeManager.dms-wallpaper
            config.flake.modules.homeManager.docker
            config.flake.modules.homeManager.fcitx5
            config.flake.modules.homeManager.fish
            config.flake.modules.homeManager.git-gh
            config.flake.modules.homeManager.gaming
            config.flake.modules.homeManager.llm-agents
            config.flake.modules.homeManager.media-cava
            config.flake.modules.homeManager.media-tools
            config.flake.modules.homeManager.music-client
            config.flake.modules.homeManager.monitoring-tools
            config.flake.modules.homeManager.nautilus
            config.flake.modules.homeManager.niri
            config.flake.modules.homeManager.packages-toolchains
            config.flake.modules.homeManager.ssh
            config.flake.modules.homeManager.starship
            config.flake.modules.homeManager.terminal-tmux
            config.flake.modules.homeManager.tui-tools
            config.flake.modules.homeManager.dev-tools
            config.flake.modules.homeManager.dev-devenv
            config.flake.modules.homeManager.desktop-base
            config.flake.modules.homeManager.editor-emacs
            config.flake.modules.homeManager.editor-neovim
            config.flake.modules.homeManager.editor-vscode
            config.flake.modules.homeManager.editor-zed
            config.flake.modules.homeManager.terminals
            config.flake.modules.homeManager.theme-base
            config.flake.modules.homeManager.theme-zen
            config.flake.modules.homeManager.wayland-tools
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
    };
}
