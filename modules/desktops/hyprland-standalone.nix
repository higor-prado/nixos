{ ... }:
{
  flake.modules.nixos.desktop-hyprland-standalone =
    { lib, pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        extraPortals = lib.mkDefault [
          pkgs.xdg-desktop-portal-gtk
          pkgs.gnome-keyring
        ];
        config.hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };

  flake.modules.homeManager.desktop-hyprland-standalone =
    { lib, pkgs, ... }:
    let
      helpers = import ../../lib/_helpers.nix;
      mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
      provisionHyprlandLuaFile =
        target: source:
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            inherit source;
            target = "$HOME/.config/hypr/${target}";
          }
        );
    in
    {
      # HM controls NIX_XDG_DESKTOP_PORTAL_DIR for user services. Include GTK and
      # gnome-keyring backends explicitly so the configured portal implementations
      # are present in the per-user portal backend directory.
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.gnome-keyring
        ];
        config.hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
          "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };

      xdg.configFile = helpers.portalPathOverrides // {
        "hypr/hyprland.lua".source = ../../config/desktops/hyprland-standalone/hyprland.lua;
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
          LimitCORE=0
        '';
      };

      home.activation.provisionHyprlandLuaActions = provisionHyprlandLuaFile "modules/actions.lua" ../../config/desktops/hyprland-standalone/modules/actions.lua;

      home.activation.provisionHyprlandLuaAppearance = provisionHyprlandLuaFile "modules/appearance.lua" ../../config/desktops/hyprland-standalone/modules/appearance.lua;

      home.activation.provisionHyprlandLuaBinds = provisionHyprlandLuaFile "modules/binds.lua" ../../config/desktops/hyprland-standalone/modules/binds.lua;

      home.activation.provisionHyprlandLuaEnv = provisionHyprlandLuaFile "modules/env.lua" ../../config/desktops/hyprland-standalone/modules/env.lua;

      home.activation.provisionHyprlandLuaInput = provisionHyprlandLuaFile "modules/input.lua" ../../config/desktops/hyprland-standalone/modules/input.lua;

      home.activation.provisionHyprlandLuaLayout = provisionHyprlandLuaFile "modules/layout.lua" ../../config/desktops/hyprland-standalone/modules/layout.lua;

      home.activation.provisionHyprlandLuaMonitors = provisionHyprlandLuaFile "modules/monitors.lua" ../../config/desktops/hyprland-standalone/modules/monitors.lua;

      home.activation.provisionHyprlandLuaRules = provisionHyprlandLuaFile "modules/rules.lua" ../../config/desktops/hyprland-standalone/modules/rules.lua;

      home.activation.provisionHyprlandScreenshotScript = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../config/desktops/hyprland-standalone/scripts/screenshot.sh;
          target = "$HOME/.config/hypr/scripts/screenshot.sh";
          mode = "0755";
        }
      );

      home.activation.provisionHyprlandLuaStartup = provisionHyprlandLuaFile "modules/startup.lua" ../../config/desktops/hyprland-standalone/modules/startup.lua;
    };
}
