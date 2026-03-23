{ inputs, ... }:
{
  flake.modules = {
    nixos.niri =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        niriPackage = inputs.niri.packages.${system}.niri-unstable;
        xwaylandSatellitePackage = inputs.niri.packages.${system}.xwayland-satellite-unstable;
        niriPortalConfig = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      in
      {
        config = {
          xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
          xdg.portal.config.niri = niriPortalConfig;

          programs.niri = {
            enable = true;
            package = niriPackage;
          };

          environment.systemPackages = [
            xwaylandSatellitePackage
          ];
        };
      };

    homeManager.niri =
      { lib, ... }:
      let
        mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../../lib/_helpers.nix;
        portalExecPath = helpers.portalExecPath;
      in
      {
        xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';

        home.activation.provisionNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../../config/apps/niri/config.kdl;
            target = "$HOME/.config/niri/config.kdl";
          }
        );
      };
  };
}
