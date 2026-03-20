{ ... }:
{
  flake.modules.homeManager.monitoring-tools =
    { ... }:
    {
      xdg.configFile."htop/htoprc".source = builtins.path {
        path = ../../../config/apps/htop/htoprc;
        name = "htoprc";
      };
    };

  den.aspects.monitoring-tools = {
    provides.to-users.homeManager =
      { ... }:
      {
        xdg.configFile."htop/htoprc".source = builtins.path {
          path = ../../../config/apps/htop/htoprc;
          name = "htoprc";
        };
      };
  };
}
