{ config, ... }:
let
  userName = config.username;
in
{
  flake.modules = {
    nixos.desktop-dms-on-hyprland =
      { lib, pkgs, ... }:
      {
        services.greetd.enable = lib.mkDefault true;
        services.greetd.settings.default_session.command =
          lib.mkOverride 2000 "/run/current-system/sw/bin/true";
        services.greetd.settings.default_session.user =
          lib.mkOverride 2000 userName;

        programs.dank-material-shell.greeter.compositor.name = lib.mkForce "hyprland";

        xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
      };

    homeManager.desktop-dms-on-hyprland =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionDmsOnHyprlandCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/dms-on-hyprland/custom.conf;
            target = "$HOME/.config/hypr/custom.conf";
          }
        );
      };
  };
}
