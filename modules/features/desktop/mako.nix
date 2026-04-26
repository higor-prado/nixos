{ ... }:
{
  flake.modules.homeManager.mako =
    { ... }:
    {
      services.mako = {
        enable = true;
        settings = {
          font = "JetBrains Mono Nerd Font 12";
          width = 500;
          height = 300;
          margin = 12;
          padding = 15;
          border-size = 2;
          border-radius = 15;
          max-visible = 5;
          default-timeout = 5000;
          icons = true;
          max-icon-size = 64;
          anchor = "top-right";
          layer = "overlay";

          "urgency=critical" = {
            default-timeout = 0;
          };
          "urgency=low" = {
            default-timeout = 3000;
          };
          "mode=do-not-disturb" = {
            invisible = true;
            default-timeout = 0;
          };
        };
      };
    };
}
