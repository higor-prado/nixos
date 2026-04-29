{ ... }:
{
  flake.modules.homeManager.nwg-dock =
    { lib, pkgs, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
      dockStyleSource = ../../../config/apps/nwg-dock/dock-catppuccin.css;
      dockStyleTarget = "$HOME/.config/nwg-dock-hyprland/style.css";
      dockArgs = [
        "-r"
        "-nolauncher"
        "-i"
        "48"
        "-p"
        "bottom"
        "-s"
        "style.css"
      ];
      dockCommand = "${pkgs.nwg-dock-hyprland}/bin/nwg-dock-hyprland ${lib.concatStringsSep " " dockArgs}";
      nwgDockRestart = pkgs.writeShellApplication {
        name = "nwg-dock-restart";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          systemctl --user restart nwg-dock-hyprland.service
        '';
      };
      nwgDockTrial = pkgs.writeShellApplication {
        name = "nwg-dock-trial";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          systemctl --user restart nwg-dock-hyprland.service
          systemctl --user --no-pager --full status nwg-dock-hyprland.service || true
        '';
      };
    in
    {
      home.packages = [
        pkgs.nwg-dock-hyprland
        nwgDockRestart
        nwgDockTrial
      ];

      home.activation.provisionNwgDockStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = dockStyleSource;
          target = dockStyleTarget;
        }
      );

      home.activation.ensureNwgDockStyleEditable = lib.hm.dag.entryAfter [ "provisionNwgDockStyle" ] ''
        target="${dockStyleTarget}"
        source=${lib.escapeShellArg "${dockStyleSource}"}

        if [ -f "$target" ] && [ ! -w "$target" ]; then
          $DRY_RUN_CMD mv "$target" "$target.before-nixos-readonly"
          $DRY_RUN_CMD cp "$source" "$target"
        fi

        if [ -f "$target" ]; then
          $DRY_RUN_CMD chmod u+rw "$target"
        fi
      '';

      home.activation.removeNwgDockLiveHotfix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        hotfix="$HOME/.config/systemd/user/nwg-dock-hyprland.service.d/live-resident-fix.conf"
        if [ -e "$hotfix" ]; then
          $DRY_RUN_CMD rm -f "$hotfix"
        fi
      '';

      systemd.user.services.nwg-dock-hyprland = {
        Unit = {
          Description = "nwg-dock-hyprland dock";
          Documentation = [ "https://github.com/nwg-piotr/nwg-dock-hyprland" ];
          After = [ "hyprland-session.target" ];
          PartOf = [ "hyprland-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "simple";
          ExecStart = dockCommand;
          Environment = [
            "HOME=%h"
            "XDG_RUNTIME_DIR=/run/user/%U"
          ];
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    };
}
