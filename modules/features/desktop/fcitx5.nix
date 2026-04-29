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
      { ... }:
      {
        i18n.inputMethod = {
          enable = true;
          type = "fcitx5";
          fcitx5.waylandFrontend = true;
          # Disable built-in clipboard addon — clipboard is managed by cliphist
          fcitx5.settings.addons = {
            clipboard.globalSection.Enabled = "False";
          };
        };
        home.sessionVariables.QT_IM_MODULE = "fcitx";
        systemd.user.services.fcitx5-daemon = {
          Unit = {
            After = [ "graphical-session.target" ];
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          Service = {
            Restart = "on-failure";
            RestartSec = 1;
          };
        };
        xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
          [Desktop Entry]
          Hidden=true
        '';
        catppuccin.fcitx5 = {
          enable = true;
          apply = true;
        };
      };
  };
}
