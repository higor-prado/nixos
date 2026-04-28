{ ... }:
{
  flake.modules.homeManager.waybar =
    { lib, pkgs, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
    in
    {
      home.packages = [ pkgs.imagemagick ];

      programs.waybar = {
        enable = true;
        systemd.enable = true;
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

      home.activation.provisionWaybarClipboardScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waybar/scripts/clipboard-history.sh;
          target = "$HOME/.config/waybar/scripts/clipboard-history.sh";
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

    };
}
