{ ... }:
{
  den.aspects.desktop-dms-on-niri = {
    nixos =
      { ... }:
      {
        imports = [
          # Desktop-common: shared baseline for all desktop experiences
          (
            { lib, pkgs, ... }:
            {
              services.greetd.enable = lib.mkDefault true;
              systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;
              xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
            }
          )

          # Composition parameterization
          {
            config.custom.niri.standaloneSession = false;
          }
        ];
      };

    homeManager =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
        portalExecPath = helpers.portalExecPath;
      in
      {
        xdg.configFile."systemd/user/xdg-desktop-portal.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';

        xdg.configFile."systemd/user/xdg-desktop-portal-gtk.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';

        home.activation.provisionDmsOnNiriCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/dms-on-niri/custom.kdl;
            target = "$HOME/.config/niri/custom.kdl";
          }
        );
      };
  };
}
