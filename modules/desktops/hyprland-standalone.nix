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
      { lib, pkgs, ... }:
      let
        helpers = import ../../lib/_helpers.nix;
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
      in
      {
        # HM controls NIX_XDG_DESKTOP_PORTAL_DIR for user services. Include GTK backend
        # explicitly so FileChooser/OpenURI/Settings are available alongside Hyprland portals.
        xdg.portal = {
          enable = true;
          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
          config.hyprland = {
            default = [ "hyprland" "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };

        xdg.configFile = helpers.portalPathOverrides // {
          "systemd/user/xdg-desktop-portal-gtk.service.d/override.conf".text = ''
            [Unit]
            ConditionEnvironment=WAYLAND_DISPLAY

            [Service]
            Environment=PATH=${helpers.portalExecPath}
            Restart=on-failure
            RestartSec=2
          '';
          "systemd/user/xdg-desktop-portal-hyprland.service.d/override.conf".text = ''
            [Service]
            Environment=PATH=${helpers.portalExecPath}
            RestartSec=2
          '';
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