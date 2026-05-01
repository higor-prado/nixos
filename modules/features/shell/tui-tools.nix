{ ... }:
{
  flake.modules.homeManager.tui-tools =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.lazydocker ];

      programs.lazygit.enable = true;
      programs.yazi = {
        enable = true;
        shellWrapperName = "yy";
      };
      programs.zellij.enable = true;
    };
}
