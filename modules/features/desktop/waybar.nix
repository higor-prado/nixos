{ inputs, ... }:
{
  flake.modules.homeManager.waybar =
    { pkgs, lib, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar;
      };

      catppuccin.waybar.mode = "createLink";

      systemd.user.services.waybar = {
        Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
        Service.RestartSec = "2";
      };

      home.activation.provisionWaybarConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/config;
          target = "$HOME/.config/waybar/config";
        }
      );

      home.activation.provisionWaybarStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/style.css;
          target = "$HOME/.config/waybar/style.css";
        }
      );

      home.activation.provisionWaybarMakoScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/scripts/mako.sh;
          target = "$HOME/.config/waybar/scripts/mako.sh";
          mode = "0755";
        }
      );

      home.activation.provisionWaybarMakoDndScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/scripts/mako-dnd.sh;
          target = "$HOME/.config/waybar/scripts/mako-dnd.sh";
          mode = "0755";
        }
      );

      home.activation.provisionWaybarMakoClearScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/scripts/mako-clear.sh;
          target = "$HOME/.config/waybar/scripts/mako-clear.sh";
          mode = "0755";
        }
      );

      home.activation.provisionWaybarActiveWindowScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/scripts/active-window.sh;
          target = "$HOME/.config/waybar/scripts/active-window.sh";
          mode = "0755";
        }
      );

      home.activation.provisionWaybarBottomConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/bottom;
          target = "$HOME/.config/waybar/bottom";
        }
      );

      systemd.user.services.waybar-bottom = {
        Unit = {
          Description = "Waybar bottom bar";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          After = [ "graphical-session.target" ];
          PartOf = [
            "tray.target"
            "graphical-session.target"
          ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${
            lib.getExe inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar
          } -c %h/.config/waybar/bottom";
          Restart = "on-failure";
          RestartSec = "2";
          KillMode = "mixed";
        };
        Install.WantedBy = [
          "tray.target"
          "graphical-session.target"
        ];
      };

    };
}
