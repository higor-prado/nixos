{ ... }:
{
  flake.modules = {
    nixos.fcitx5 =
      { pkgs, ... }:
      {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5.addons = [ pkgs.fcitx5-gtk ];
          fcitx5.settings.inputMethod = {
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "keyboard-us-alt-intl";
              DefaultIM = "keyboard-us-alt-intl";
            };
            "Groups/0/Items/0" = {
              Name = "keyboard-us-alt-intl";
              Layout = "";
            };
            "GroupOrder"."0" = "Default";
          };
        };
      };

    homeManager.fcitx5 =
      { lib, pkgs, ... }:
      let
        waitForWaylandSocket = pkgs.writeShellScript "fcitx5-wait-for-wayland-socket" ''
          set -eu

          runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          display_name="''${WAYLAND_DISPLAY:-wayland-1}"
          socket="$runtime_dir/$display_name"

          attempts=0
          while [ "$attempts" -lt 50 ]; do
            if [ -S "$socket" ]; then
              exit 0
            fi

            ${pkgs.coreutils}/bin/sleep 0.2
            attempts=$((attempts + 1))
          done

          echo "fcitx5-daemon: timed out waiting for Wayland socket $socket" >&2
          exit 1
        '';
      in
      {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5.waylandFrontend = true;
        };
        home.sessionVariables.QT_IM_MODULE = "fcitx";
        systemd.user.services.fcitx5-daemon = {
          Unit.After = [ "graphical-session.target" ];
          Service = {
            ExecStartPre = [ "${waitForWaylandSocket}" ];
            Restart = "on-failure";
            RestartSec = 1;
          };
        };
        xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
          [Desktop Entry]
          Hidden=true
        '';
        catppuccin.fcitx5 = lib.mkForce {
          enable = true;
          apply = true;
        };
      };
  };
}
