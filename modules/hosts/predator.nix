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
      (den.lib.perHost {
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
      })
    ];

    _.to-users.includes = with den.aspects; [
      docker._.to-users
      packages-toolchains._.to-users
      backup-service._.to-users
      llm-agents._.to-users
      fish._.to-users
      git-gh._.to-users
      starship._.to-users
      tui-tools._.to-users
      terminal-tmux._.to-users
      media-cava._.to-users
      media-tools._.to-users
      gaming._.to-users
      ssh._.to-users
      theme._.to-users
      desktop-dms-on-niri._.to-users
      niri._.to-users
      dms._.to-users
      dms-wallpaper._.to-users
      fcitx5._.to-users
      nautilus._.to-users
      desktop-base._.to-users
      desktop-apps._.to-users
      desktop-viewers._.to-users
      wayland-tools._.to-users
      monitoring-tools._.to-users
      music-client._.to-users
      core-user-packages._.to-users
      editor-neovim._.to-users
      editor-vscode._.to-users
      editor-emacs._.to-users
      editor-zed._.to-users
      terminals._.to-users
      dev-tools._.to-users
      dev-devenv._.to-users
    ];

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
