{ inputs, ... }:
{
  flake.modules = {
    nixos.hyprland =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        programs.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${system}.hyprland;
          xwayland.enable = true;
          withUWSM = false;
        };

      };

    homeManager.hyprland =
      { pkgs, ... }:
      let
        sessionStart = pkgs.writeShellScript "hyprland-session-start" ''
          set -euo pipefail

          systemctl=${pkgs.systemd}/bin/systemctl
          dbus_update=${pkgs.dbus}/bin/dbus-update-activation-environment

          # Clear stale graphical-session state before starting this compositor session.
          "$systemctl" --user stop hyprland-session.target graphical-session.target || true

          # Portals are D-Bus activatable and may have inherited a pre-Hyprland environment.
          "$systemctl" --user stop \
            xdg-desktop-portal.service \
            xdg-desktop-portal-gtk.service \
            xdg-desktop-portal-hyprland.service || true

          "$systemctl" --user reset-failed \
            waybar.service \
            network-manager-applet.service \
            blueman-applet.service \
            udiskie.service \
            vicinae.service \
            cliphist.service \
            cliphist-images.service \
            fcitx5-daemon.service \
            hyprpolkitagent.service \
            awww-daemon.service \
            xdg-desktop-portal.service \
            xdg-desktop-portal-gtk.service \
            xdg-desktop-portal-hyprland.service || true

          "$dbus_update" --systemd \
            DISPLAY \
            WAYLAND_DISPLAY \
            HYPRLAND_INSTANCE_SIGNATURE \
            XDG_CURRENT_DESKTOP \
            XDG_SESSION_DESKTOP \
            XDG_SESSION_TYPE \
            DESKTOP_SESSION \
            NIX_XDG_DESKTOP_PORTAL_DIR

          "$systemctl" --user start hyprland-session.target
        '';
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          systemd.enable = false;
        };

        systemd.user.targets.hyprland-session = {
          Unit = {
            Description = "Hyprland compositor session";
            Documentation = [ "man:systemd.special(7)" ];
            BindsTo = [ "graphical-session.target" ];
            Wants = [
              "graphical-session-pre.target"
              "xdg-desktop-autostart.target"
            ];
            After = [ "graphical-session-pre.target" ];
            Before = [ "xdg-desktop-autostart.target" ];
          };
        };

        # Lua is the runtime entrypoint now. Keep the session bootstrap in a
        # dedicated Lua module and require it from ~/.config/hypr/hyprland.lua.
        xdg.configFile."hypr/session-bootstrap.lua".text = ''
          hl.env("XDG_CURRENT_DESKTOP", "Hyprland", true)
          hl.env("XDG_SESSION_DESKTOP", "Hyprland", true)
          hl.env("XDG_SESSION_TYPE", "wayland", true)
          hl.env("DESKTOP_SESSION", "hyprland", true)

          hl.on("hyprland.start", function()
              hl.timer(function()
                  hl.exec_cmd("${sessionStart}")
              end, { timeout = 250, type = "oneshot" })
          end)

          return true
        '';
      };
  };
}
