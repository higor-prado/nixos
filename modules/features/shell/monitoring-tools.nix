{ ... }:
{
  flake.modules.homeManager.monitoring-tools =
    { pkgs, ... }:
    {
      programs.btop = {
        enable = true;
        package = pkgs.btop-cuda;
      };
      programs.bottom.enable = true;

      home.packages = with pkgs; [
        htop
        fastfetch
        smartmontools
      ];

      xdg.configFile."htop/htoprc".source = builtins.path {
        path = ../../../config/apps/htop/htoprc;
        name = "htoprc";
      };
    };
}
