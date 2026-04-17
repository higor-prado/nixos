{ config, ... }:
let
  userName = config.username;
in
{
  flake.modules = {
    nixos.desktop-noctalia-on-niri =
      { lib, pkgs, ... }:
      {
        services.greetd.enable = lib.mkDefault true;
        services.greetd.settings.default_session.command =
          lib.mkOverride 2000 "/run/current-system/sw/bin/true";
        services.greetd.settings.default_session.user =
          lib.mkOverride 2000 userName;
        systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;
        xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

    homeManager.desktop-noctalia-on-niri =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionNoctaliaOnNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/noctalia-on-niri/custom.kdl;
            target = "$HOME/.config/niri/custom.kdl";
          }
        );
      };
  };
}
