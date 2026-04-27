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

      # Fix restart limits for session applets that race with Wayland compositor startup
      systemd.user.services.cliphist.Service.RestartSec = "2";
      systemd.user.services.wl-clip-persist.Service.RestartSec = "2";
    };
}
