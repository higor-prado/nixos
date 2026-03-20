# Predator host composition - desktop workstation.
{ inputs, config, ... }:
let
  system = "x86_64-linux";
  customPkgs = import ../../pkgs {
    pkgs = inputs.nixpkgs.legacyPackages.${system};
    inherit inputs;
  };
  llmAgentsPkgs = inputs.llm-agents.packages.${system} or { };
  llmAgentsHomePackages = with llmAgentsPkgs; [
    claude-code
    codex
    crush
    kilocode-cli
    opencode
  ];
  hostName = "predator";
  hardwareImports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ../../hardware/predator/default.nix
  ];
  extraSystemPackages = [ customPkgs.predator-tui ];
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
    npusi = "nh os info";
    npust = "nixos-version --json; systemctl --failed --no-pager --legend=0 || true";
    npuc = "nh clean all";
    npuct = "systemctl status nh-clean.timer --no-pager";
    nau = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock";
    naub = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os build path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    naut = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os test path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    naus = "nix flake update --flake path:$HOME/nixos && git -C \"$HOME/nixos\" diff flake.lock && nh os switch path:$HOME/nixos#aurelius --target-host aurelius --build-host aurelius --out-link \"$HOME/nixos/result-aurelius\" -e passwordless";
    naui = "ssh aurelius 'nh os info'";
    nausi = "ssh aurelius 'nh os info'";
    naust = "ssh aurelius 'nixos-version --json; systemctl --failed --no-pager --legend=0 || true'";
    nauc = "ssh aurelius 'sudo -n /run/current-system/sw/bin/nh clean all -e none'";
    nauct = "ssh aurelius 'systemctl status nh-clean.timer --no-pager'";
  };
in
{
  repo.hosts.predator = {
    inherit system;
    role = "desktop";
    trackedUsers = [ "higorprado" ];
  };

  configurations.nixos.predator.module =
    let
      inherit (config.flake.modules) homeManager nixos;
      hostInventory = config.repo.hosts.${hostName};
      userName = config.username;
    in
    {
      imports = [
        inputs.home-manager.nixosModules.home-manager
        nixos.repo-runtime-contracts
        nixos.system-base
        nixos.home-manager-settings
        nixos.networking
        nixos.security
        nixos.keyboard
        nixos.nixpkgs-settings
        nixos.maintenance
        nixos.tailscale
        nixos.audio
        nixos.gnome-keyring
        nixos.bluetooth
        inputs.niri.nixosModules.niri
        inputs.dms.nixosModules.dank-material-shell
        inputs.dms.nixosModules.greeter
        inputs.keyrs.nixosModules.default
        nixos.desktop-dms-on-niri
        nixos.dms
        nixos.maintenance-smartd
        nixos.networking-avahi
        nixos.networking-resolved
        nixos.niri
        nixos.nix-settings-desktop
        nixos.podman
        nixos.upower
        nixos.higorprado
        nixos.editor-neovim
        nixos.fcitx5
        nixos.gaming
        nixos.keyrs
        nixos.nix-settings
        nixos.nautilus
        nixos.packages-docs-tools
        nixos.packages-fonts
        nixos.packages-system-tools
        nixos.packages-toolchains
        nixos.docker
        nixos.fish
        nixos.ssh
        nixos.xwayland
      ] ++ hardwareImports;

      nixpkgs.hostPlatform = hostInventory.system;
      networking.hostName = hostName;

      custom = {
        host.role = hostInventory.role;
        user.name = userName;
      };

      environment.systemPackages = extraSystemPackages;

      users.users.${userName}.extraGroups = predatorUserExtraGroups;

      home-manager = {
        users.${userName} = {
          imports = [
            homeManager.higorprado
            homeManager.backup-service
            homeManager.core-user-packages
            homeManager.desktop-apps
            homeManager.desktop-viewers
            homeManager.desktop-dms-on-niri
            homeManager.dms
            homeManager.dms-wallpaper
            homeManager.docker
            homeManager.fcitx5
            homeManager.fish
            homeManager.git-gh
            homeManager.gaming
            homeManager.media-cava
            homeManager.media-tools
            homeManager.music-client
            homeManager.monitoring-tools
            homeManager.nautilus
            homeManager.niri
            homeManager.packages-toolchains
            homeManager.ssh
            homeManager.starship
            homeManager.terminal-tmux
            homeManager.tui-tools
            homeManager.dev-tools
            homeManager.dev-devenv
            homeManager.desktop-base
            homeManager.editor-emacs
            homeManager.editor-neovim
            homeManager.editor-vscode
            homeManager.editor-zed
            homeManager.terminals
            homeManager.theme-base
            homeManager.theme-zen
            homeManager.wayland-tools
          ];

          home.packages = llmAgentsHomePackages;

          programs.fish.shellAbbrs = operatorFishAbbrs;
        };
      };
    };
}
