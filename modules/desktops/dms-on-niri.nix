{ ... }:
{
  flake.modules = {
    nixos.desktop-dms-on-niri =
      { lib, pkgs, ... }:
      {
        services.greetd.enable = lib.mkDefault true;
        systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;
        xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
        custom.niri.standaloneSession = false;
      };

    homeManager.desktop-dms-on-niri =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionDmsOnNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/dms-on-niri/custom.kdl;
            target = "$HOME/.config/niri/custom.kdl";
          }
        );
      };
  };
}
