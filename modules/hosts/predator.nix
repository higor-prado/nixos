# Predator host composition - desktop workstation.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  hostName = "predator";
  hardwareImports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ../../hardware/predator/default.nix
  ];
  predatorUserExtraGroups = [
    "video"
    "audio"
    "input"
    "docker"
    "rfkill"
    "uinput"
    "linuwu_sense"
  ];
in
{
  configurations.nixos.predator.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;

      nixosInfrastructure = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
        nixos.nix-cache-settings
        nixos.attic-publisher
      ];
      nixosCoreServices = [
        nixos.networking
        nixos.networking-avahi
        nixos.networking-resolved
        nixos.networking-wireguard-client
        nixos.security
        nixos.keyboard
        nixos.maintenance
        nixos.maintenance-smartd
        nixos.tailscale
        nixos.audio
        nixos.bluetooth
        nixos.upower
        nixos.podman
        nixos.docker
      ];
      nixosDesktop = [
        inputs.hyprland.nixosModules.default
        inputs.keyrs.nixosModules.default
        nixos.desktop-hyprland-standalone
        nixos.gdm
        nixos.fcitx5
        nixos.gaming
        nixos.gnome-keyring
        nixos.keyrs
        nixos.hyprland
        nixos.nautilus
      ];

      nixosUserTools = [
        nixos.editors-neovim
        nixos.fish
        nixos.higorprado
        nixos.fonts
        nixos.server-tools
        nixos.ssh
      ];

      hmUserTools = [
        homeManager.higorprado
        homeManager.attic-client
        homeManager.keyboard
        homeManager.backup-service
        homeManager.core-user-packages
        homeManager.docker
        homeManager.git-gh
        homeManager.monitoring-tools
        homeManager.server-tools
        homeManager.podman
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.mosh
        homeManager.starship
        homeManager.tmux
        homeManager.terminals
        homeManager.tui-tools
      ];
      hmDesktop = [
        homeManager.browsers
        homeManager.desktop-base
        homeManager.desktop-apps
        homeManager.desktop-hyprland-standalone
        homeManager.desktop-viewers
        homeManager.mime-defaults
        homeManager.fcitx5
        homeManager.gnome-keyring
        homeManager.gaming
        homeManager.hyprland
        homeManager.mako
        homeManager.qt-theme
        homeManager.walker
        homeManager.session-applets
        homeManager.waypaper
        homeManager.waybar
        homeManager.media-tools
        homeManager.music-client
        homeManager.nautilus
        homeManager.theme-base
        homeManager.theme-zen
        homeManager.wayland-tools
      ];

      hmDev = [
        homeManager.devenv
        homeManager.editors-emacs
        homeManager.editors-neovim
        homeManager.editors-vscode
        homeManager.editors-zed
        homeManager.llm-agents
        homeManager.llm-paseo
        homeManager.toolchains
        homeManager.linters
        homeManager.docs-tools
      ];
    in
    { pkgs, ... }:
    {
      imports =
        nixosInfrastructure ++ nixosCoreServices ++ nixosDesktop ++ nixosUserTools ++ hardwareImports;

      nixpkgs.hostPlatform = system;
      networking.hostName = hostName;

      # ═══════════════════════════════════════════════════════════════
      # nix-ld — FHS compatibility layer for precompiled binaries
      # ═══════════════════════════════════════════════════════════════
      #
      # nix-ld creates /lib64/ld-linux-x86-64.so.2, the default Linux
      # dynamic linker that NixOS deliberately omits. Precompiled binaries
      # (Zed extensions, global npm/pip packages, etc.) that have this path
      # hardcoded will now execute normally.
      #
      # Library list: uses the nixpkgs default (14 common libs:
      # zlib, zstd, stdenv.cc.cc, curl, openssl, attr, libssh,
      # bzip2, libxml2, acl, libsodium, util-linux, xz, systemd).
      #
      # ╔══════════════════════════════════════════════════════════╗
      # ║  RISKS (tradeoffs accepted for desktop convenience)     ║
      # ╠══════════════════════════════════════════════════════════╣
      # ║ 1. Security: binaries downloaded outside Nix (curl,    ║
      # ║    wget, npm, pip) now execute. NixOS default rejects  ║
      # ║    them.                                                ║
      # ║                                                         ║
      # ║ 2. Incompatibility: Nix lib versions may differ from   ║
      # ║    what the binary expects → silent crashes.           ║
      # ║    Debug: run the binary with NIX_LD_LOG=debug.        ║
      # ║                                                         ║
      # ║ 3. Non-declarative: binaries are not in flake.lock,    ║
      # ║    not CI-tested, no verifiable hash.                  ║
      # ║    Prefer packaging via Nix whenever possible.         ║
      # ║                                                         ║
      # ║ 4. Auditing: run scripts/audit-nix-ld-usage.sh to      ║
      # ║    audit installed binaries that use nix-ld.           ║
      # ╚══════════════════════════════════════════════════════════╝
      programs.nix-ld.enable = true;

      environment.etc."xdg/monitors.xml".source = ../../config/desktops/gdm/predator-monitors.xml;

      environment.systemPackages = [
        pkgs.tpm2-tools
        pkgs.ethtool
      ];

      users.users.${userName}.extraGroups = predatorUserExtraGroups;

      home-manager = {
        users.${userName} =
          { pkgs, ... }:
          let
            customPkgs = import ../../pkgs { inherit pkgs inputs; };
          in
          {
            imports = [
              inputs.spicetify-nix.homeManagerModules.spicetify
            ]
            ++ hmUserTools
            ++ hmShell
            ++ hmDesktop
            ++ hmDev;

            home.packages = [
              customPkgs.predator-tui
              pkgs.nvtopPackages.nvidia
            ];

            programs.fish.shellAbbrs = {
              npu = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
              npub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-predator\"";
              nput = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-predator\"";
              npus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/.cache/nh-result-predator\"";
              npui = "nh os info";
              npust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
              npuc = "nh clean all";
              npuct = "systemctl status nh-clean.timer --no-pager";
              naub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/.cache/nh-result-aurelius\" -e passwordless";
              naut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/.cache/nh-result-aurelius\" -e passwordless";
              naus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/.cache/nh-result-aurelius\" -e passwordless";
              adev = "ssh -t aurelius 'tmux new -As dev'";
              naui = "ssh aurelius 'nh os info'";
              naust = "ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
              nauc = "ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
              nauct = "ssh aurelius 'systemctl status nh-clean.timer --no-pager'";
              ncub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/.cache/nh-result-cerebelo\" -e passwordless";
              ncut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/.cache/nh-result-cerebelo\" -e passwordless";
              ncus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/.cache/nh-result-cerebelo\" -e passwordless";
              cdev = "ssh -t cerebelo 'tmux new -As dev'";
              ncui = "ssh cerebelo 'nh os info'";
              ncust = "ssh cerebelo 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
              ncuc = "ssh cerebelo 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
              ncuct = "ssh cerebelo 'systemctl status nh-clean.timer --no-pager'";
            };
          };
      };
    };
}
