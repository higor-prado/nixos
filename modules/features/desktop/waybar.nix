{ ... }:
{
  flake.modules.homeManager.waybar =
    { lib, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
    in
    {
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
    };
}
