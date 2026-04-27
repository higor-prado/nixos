{ ... }:
{
  flake.modules.homeManager.session-applets =
    { ... }:
    {
      xsession.preferStatusNotifierItems = true;

      services.hyprpolkitagent.enable = true;

      services.network-manager-applet.enable = true;
      services.blueman-applet.enable = true;
      services.udiskie.enable = true;

      services.cliphist = {
        enable = true;
        allowImages = true;
      };

      services.wl-clip-persist.enable = true;

      # Display-bound services must not start from a non-graphical user manager
      # (for example SSH/linger before Hyprland exports WAYLAND_DISPLAY).
      systemd.user.services = {
        hyprpolkitagent = {
          Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
          Service = {
            Restart = "on-failure";
            RestartSec = "2";
          };
        };

        network-manager-applet = {
          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Wants = [ "waybar.service" ];
            After = [ "waybar.service" ];
          };
          Service = {
            Restart = "on-failure";
            RestartSec = "2";
          };
        };

        blueman-applet = {
          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Wants = [ "waybar.service" ];
            After = [ "waybar.service" ];
          };
          Service = {
            Restart = "on-failure";
            RestartSec = "2";
          };
        };

        udiskie = {
          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Wants = [ "waybar.service" ];
            After = [ "waybar.service" ];
          };
          Service = {
            Restart = "on-failure";
            RestartSec = "2";
          };
        };

        cliphist = {
          Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
          Service.RestartSec = "2";
        };

        cliphist-images = {
          Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
          Service.RestartSec = "2";
        };

        wl-clip-persist = {
          Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
          Service.RestartSec = "2";
        };
      };
    };
}
