# Predator host composition - desktop workstation.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
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
  operatorFishAbbrs = {
    npu = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
    npub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
    nput = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
    npus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos --out-link \"$HOME/nixos/result\"";
    npui = "nh os info";
    npust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
    npuc = "nh clean all";
    npuct = "systemctl status nh-clean.timer --no-pager";
    naub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    naut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    naus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    adev = "ssh -t aurelius 'tmux new -As dev'";
    naui = "ssh aurelius 'nh os info'";
    naust = "ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
    nauc = "ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
    nauct = "ssh aurelius 'systemctl status nh-clean.timer --no-pager'";
    ncub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/nixos/result-cerebelo\" -e passwordless";
    ncut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/nixos/result-cerebelo\" -e passwordless";
    ncus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#cerebelo --target-host cerebelo --build-host cerebelo --out-link \"$HOME/nixos/result-cerebelo\" -e passwordless";
    cdev = "ssh -t cerebelo 'tmux new -As dev'";
    ncui = "ssh cerebelo 'nh os info'";
    ncust = "ssh cerebelo 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
    ncuc = "ssh cerebelo 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
    ncuct = "ssh cerebelo 'systemctl status nh-clean.timer --no-pager'";
  };
in
{
  configurations.nixos =
    let
      inherit (config.flake.modules) homeManager nixos;
      userName = config.username;

      nixosInfrastructure = [
        inputs.home-manager.nixosModules.home-manager
        nixos.system-base
        nixos.home-manager-settings
        nixos.nixpkgs-settings
        nixos.nix-settings
        nixos.nix-settings-desktop
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
      nixosDesktopNiri = [
        inputs.niri.nixosModules.niri
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms.nixosModules.greeter
        inputs.keyrs.nixosModules.default
        nixos.desktop-dms-on-niri
        nixos.dms
        nixos.fcitx5
        nixos.gaming
        nixos.gnome-keyring
        nixos.keyrs
        nixos.nautilus
        nixos.niri
        nixos.xwayland
      ];
      nixosDesktopNoctalia = [
        inputs.niri.nixosModules.niri
        inputs.keyrs.nixosModules.default
        nixos.desktop-noctalia-on-niri
        nixos.noctalia
        nixos.fcitx5
        nixos.gaming
        nixos.gnome-keyring
        nixos.keyrs
        nixos.nautilus
        nixos.niri
        nixos.xwayland
      ];
      nixosDesktopHyprland = [
        inputs.hyprland.nixosModules.default
        inputs.keyrs.nixosModules.default
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms.nixosModules.greeter
        nixos.desktop-hyprland-standalone
        nixos.dms
        nixos.fcitx5
        nixos.gaming
        nixos.gnome-keyring
        nixos.keyrs
        nixos.hyprland
        nixos.nautilus
      ];

      nixosUserTools = [
        nixos.editor-neovim
        nixos.fish
        nixos.higorprado
        nixos.packages-fonts
        nixos.packages-system-tools
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
        homeManager.podman
        homeManager.ssh
      ];
      hmShell = [
        homeManager.fish
        homeManager.mosh
        homeManager.starship
        homeManager.terminal-tmux
        homeManager.terminals
        homeManager.tui-tools
      ];
      hmDesktopNiri = [
        homeManager.desktop-base
        homeManager.desktop-apps
        homeManager.desktop-viewers
        homeManager.desktop-dms-on-niri
        homeManager.dms
        homeManager.dms-wallpaper
        homeManager.fcitx5
        homeManager.gaming
        homeManager.media-cava
        homeManager.media-tools
        homeManager.music-client
        homeManager.nautilus
        homeManager.niri
        homeManager.theme-base
        homeManager.theme-zen
        homeManager.wayland-tools
      ];
      hmDesktopNoctalia = [
        homeManager.desktop-base
        homeManager.desktop-apps
        homeManager.desktop-viewers
        homeManager.desktop-noctalia-on-niri
        homeManager.fcitx5
        homeManager.gaming
        homeManager.media-cava
        homeManager.media-tools
        homeManager.music-client
        homeManager.nautilus
        homeManager.niri
        homeManager.noctalia
        homeManager.theme-base
        homeManager.theme-zen
        homeManager.wayland-tools
      ];
      hmDesktopHyprland = [
        homeManager.desktop-base
        homeManager.desktop-apps
        homeManager.desktop-hyprland-standalone
        homeManager.desktop-viewers
        homeManager.fcitx5
        homeManager.gaming
        homeManager.hyprland
        homeManager.rofi
        homeManager.dunst
        homeManager.waypaper
        homeManager.media-cava
        homeManager.waybar
        homeManager.media-tools
        homeManager.music-client
        homeManager.nautilus
        homeManager.theme-base
        homeManager.theme-zen
        homeManager.wayland-tools
      ];

      hmDev = [
        homeManager.dev-devenv
        homeManager.dev-tools
        homeManager.editor-emacs
        homeManager.editor-neovim
        homeManager.editor-vscode
        homeManager.editor-zed
        homeManager.llm-agents
        homeManager.packages-docs-tools
        homeManager.packages-toolchains
      ];
      mkPredatorConfig = nixosDesktop: hmDesktop: {
        imports =
          nixosInfrastructure ++ nixosCoreServices ++ nixosDesktop ++ nixosUserTools ++ hardwareImports;

        nixpkgs.hostPlatform = system;
        networking.hostName = hostName;

        environment.systemPackages = [ inputs.nixpkgs.legacyPackages.${system}.tpm2-tools ];

        users.users.${userName}.extraGroups = predatorUserExtraGroups;

        home-manager = {
          users.${userName} =
            { pkgs, ... }:
            {
              imports = hmUserTools ++ hmShell ++ hmDesktop ++ hmDev;

              home.packages = [
                customPkgs.predator-tui
                pkgs.nvtopPackages.nvidia
              ];

              programs.fish.shellAbbrs = operatorFishAbbrs;
            };
        };
      };
    in
    {
      # predator.module = mkPredatorConfig nixosDesktopNiri hmDesktopNiri;
      # predator.module = mkPredatorConfig nixosDesktopNoctalia hmDesktopNoctalia;
      predator.module = mkPredatorConfig nixosDesktopHyprland hmDesktopHyprland;
    };
}
