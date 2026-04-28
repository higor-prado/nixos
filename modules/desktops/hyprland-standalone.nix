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

        home.activation.provisionHyprlandLuaEntrypoint = provisionHyprlandLuaFile
          "hyprland.lua"
          ../../config/desktops/hyprland-standalone/hyprland.lua;

        home.activation.provisionHyprlandLuaActions = provisionHyprlandLuaFile
          "modules/actions.lua"
          ../../config/desktops/hyprland-standalone/modules/actions.lua;

        home.activation.provisionHyprlandLuaAppearance = provisionHyprlandLuaFile
          "modules/appearance.lua"
          ../../config/desktops/hyprland-standalone/modules/appearance.lua;

        home.activation.provisionHyprlandLuaBinds = provisionHyprlandLuaFile
          "modules/binds.lua"
          ../../config/desktops/hyprland-standalone/modules/binds.lua;

        home.activation.provisionHyprlandLuaEnv = provisionHyprlandLuaFile
          "modules/env.lua"
          ../../config/desktops/hyprland-standalone/modules/env.lua;

        home.activation.provisionHyprlandLuaInput = provisionHyprlandLuaFile
          "modules/input.lua"
          ../../config/desktops/hyprland-standalone/modules/input.lua;

        home.activation.provisionHyprlandLuaLayout = provisionHyprlandLuaFile
          "modules/layout.lua"
          ../../config/desktops/hyprland-standalone/modules/layout.lua;

        home.activation.provisionHyprlandLuaMonitors = provisionHyprlandLuaFile
          "modules/monitors.lua"
          ../../config/desktops/hyprland-standalone/modules/monitors.lua;

        home.activation.provisionHyprlandLuaRules = provisionHyprlandLuaFile
          "modules/rules.lua"
          ../../config/desktops/hyprland-standalone/modules/rules.lua;

        home.activation.provisionHyprlandLuaStartup = provisionHyprlandLuaFile
          "modules/startup.lua"
          ../../config/desktops/hyprland-standalone/modules/startup.lua;

      };
  };
}