{ ... }:
{
  den.aspects.monitoring-tools = {
    homeManager =
      { ... }:
      {
        xdg.configFile."htop/htoprc".source = builtins.path {
          path = ../../../config/apps/htop/htoprc;
          name = "htoprc";
        };
      };
  };
}
