{ ... }:
{
  flake.modules = {
    nixos.desktop-hyprland-standalone =
      { lib, pkgs, ... }:
      {
        xdg.portal = {
          enable = true;
          extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
          config.hyprland = {
            default = [ "hyprland" "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
      };

    homeManager.desktop-hyprland-standalone =
      { lib, ... }:
      let
        helpers = import ../../lib/_helpers.nix;
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
      in
      {
        xdg.configFile = helpers.portalPathOverrides // {
          "systemd/user/xdg-desktop-portal-hyprland.service.d/override.conf".text = ''
            [Service]
            Environment=PATH=${helpers.portalExecPath}
          '';
        };

        systemd.user.services.xdg-desktop-portal-gtk = {
          Unit.PartOf = [ "xdg-desktop-portal.service" ];
          Install.WantedBy = [ "xdg-desktop-portal.service" ];
        };

        home.activation.provisionHyprlandUserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/hyprland-standalone/hyprland.conf;
            target = "$HOME/.config/hypr/user.conf";
          }
        );
      };
  };
}