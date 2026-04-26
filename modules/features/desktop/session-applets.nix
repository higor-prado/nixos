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
    };
}
