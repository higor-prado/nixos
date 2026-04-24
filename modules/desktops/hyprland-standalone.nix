{ config, ... }:
let
  userName = config.username;
in
{
  flake.modules = {
    nixos.desktop-hyprland-standalone =
      { lib, pkgs, ... }:
      {
        services.greetd.enable = lib.mkDefault true;
        services.greetd.settings.default_session.command =
          lib.mkOverride 2000 "/run/current-system/sw/bin/true";
        services.greetd.settings.default_session.user =
          lib.mkOverride 2000 userName;
        programs.dank-material-shell.greeter.compositor.name = "hyprland";
        xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
      };

    homeManager.desktop-hyprland-standalone =
      { lib, ... }:
      let
        helpers = import ../../lib/_helpers.nix;
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionHyprlandUserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/hyprland-standalone/hyprland.conf;
            target = "$HOME/.config/hypr/user.conf";
          }
        );
      };
  };
}
