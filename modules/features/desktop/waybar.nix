{ ... }:
{
  flake.modules.homeManager.waybar =
    { lib, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
    in
    {
      programs.waybar.enable = true;

      catppuccin.waybar.mode = "createLink";

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
