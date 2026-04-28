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
  operatorFishAbbrs = {
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
      nixosDesktop = [
        inputs.hyprland.nixosModules.default
        inputs.keyrs.nixosModules.default
        nixos.desktop-hyprland-standalone
        nixos.regreet
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
      hmDesktop = [
        homeManager.desktop-base
        homeManager.desktop-apps
        homeManager.desktop-hyprland-standalone
        homeManager.desktop-viewers
        homeManager.fcitx5
        homeManager.gaming
        homeManager.hyprland
        homeManager.rofi
        homeManager.wlogout
        homeManager.mako
        homeManager.qt-theme
        homeManager.session-applets
        homeManager.waypaper
        homeManager.media-cava
        homeManager.waybar
        homeManager.satty
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
            let
              customPkgs = import ../../pkgs { inherit pkgs inputs; };
            in
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
      predator.module = mkPredatorConfig nixosDesktop hmDesktop;
    };
}
