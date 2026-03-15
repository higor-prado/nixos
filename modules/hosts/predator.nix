# Predator host composition - desktop workstation (den-native).
{ den, inputs, ... }:
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
in
{
  den.hosts.x86_64-linux.predator = {
    users.higorprado.classes = [ "homeManager" ];
    # Den-level context for parametric aspects (homeManager class)
    inherit inputs customPkgs llmAgents;
  };

  den.aspects.predator = den.lib.parametric {
    includes = with den.aspects; [
      # System
      home-manager-settings
      networking-resolved
      networking-avahi
      audio
      bluetooth
      docker
      podman
      maintenance-smartd
      upower

      # Packages
      packages-fonts
      packages-system-tools
      packages-toolchains
      packages-docs-tools

      # Nix
      nix-settings-desktop

      # Backup & agents
      backup-service
      llm-agents

      # Shell & prompt
      fish
      git-gh
      keyrs
      starship
      tui-tools
      terminal-tmux

      # Media & gaming
      media-cava
      media-tools
      gaming

      # Remote & secrets
      ssh
      gnome-keyring

      # Desktop
      theme
      desktop-dms-on-niri
      niri
      dms
      dms-wallpaper
      fcitx5
      nautilus
      desktop-base
      desktop-apps
      desktop-viewers
      wayland-tools
      xwayland

      # Dev & editors
      monitoring-tools
      music-client
      core-user-packages
      editor-neovim
      editor-vscode
      editor-emacs
      editor-zed
      terminals
      dev-tools
      dev-devenv
    ];

    nixos =
      { ... }:
      {
        config = {
          environment.systemPackages = [ customPkgs.predator-tui ];
        };
        imports = [
          inputs.disko.nixosModules.disko
          inputs.impermanence.nixosModules.impermanence
          ../../hardware/predator/default.nix
        ];
      };

    provides.higorprado =
      { ... }:
      {
        homeManager =
          { ... }:
          {
            programs.fish.shellAbbrs = {
              npu = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
              npub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
              nput = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
              npus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
              npui = "nh os info";
              npust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
              npuc = "nh clean all";
              npuct = "systemctl status nh-clean.timer --no-pager";
              nau = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
              naub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
              naut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
              naus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
              naui = "ssh aurelius 'nh os info'";
              naust = "ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
              nauc = "ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
              nauct = "ssh aurelius 'systemctl status nh-clean.timer --no-pager'";
            };
          };
      };
  };
}
