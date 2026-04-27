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

        programs.hyprlock.enable = true;

      };

    homeManager.hyprland =
      { lib, pkgs, ... }:
      let
        mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
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
            cliphist.service \
            cliphist-images.service \
            wl-clip-persist.service \
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
            XDG_SESSION_TYPE \
            NIX_XDG_DESKTOP_PORTAL_DIR

          "$systemctl" --user start hyprland-session.target
        '';
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
          systemd = {
            variables = [
              "DISPLAY"
              "HYPRLAND_INSTANCE_SIGNATURE"
              "WAYLAND_DISPLAY"
              "XDG_CURRENT_DESKTOP"
              "XDG_SESSION_TYPE"
              "NIX_XDG_DESKTOP_PORTAL_DIR"
            ];
            extraCommands = lib.mkForce [ "${sessionStart}" ];
          };
          # user.conf is provisioned by the desktop composition module (e.g. hyprland-standalone.nix)
          extraConfig = "source = ~/.config/hypr/user.conf";
        };

        services.hypridle.enable = true;

        systemd.user.services.hypridle.Unit.ConditionEnvironment = "WAYLAND_DISPLAY";

        home.activation.provisionHypridleConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../../config/apps/hypridle/hypridle.conf;
            target = "$HOME/.config/hypr/hypridle.conf";
          }
        );
      };
  };
}
