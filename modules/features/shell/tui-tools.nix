{ ... }:
{
  den.aspects.tui-tools = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lazydocker ];

        programs.lazygit.enable = true;
        programs.yazi = {
          enable = true;
          # Override shellWrapperName in your private user override if needed.
          shellWrapperName = "yy";
        };
        programs.zellij.enable = true;
      };
  };
}
