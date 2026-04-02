{ ... }:
{
  flake.modules = {
    nixos.hyprland =
      { pkgs, ... }:
      let
        hyprlandPortalConfig = {
          default = [ "hyprland" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [ "hyprland" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      in
      {
        programs.hyprland.enable = true;

        xdg.portal.extraPortals = [
          pkgs.xdg-desktop-portal-gnome
          pkgs.xdg-desktop-portal-gtk
        ];
        xdg.portal.config.hyprland = hyprlandPortalConfig;
      };

    homeManager.hyprland =
      { ... }:
      let
        helpers = import ../../../lib/_helpers.nix;
        portalExecPath = helpers.portalExecPath;
      in
      {
        xdg.configFile."hypr/base.conf".source = ../../../config/apps/hypr/base.conf;
        xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';

        wayland.windowManager.hyprland = {
          enable = true;
          package = null;
          portalPackage = null;
          systemd.enable = true;
          extraConfig = ''
            source = ~/.config/hypr/base.conf
            source = ~/.config/hypr/custom.conf
          '';
        };
      };
  };
}
