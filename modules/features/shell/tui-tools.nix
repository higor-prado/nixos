{ ... }:
{
  den.aspects.tui-tools = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.lazydocker ];

        programs.lazygit.enable = true;
        programs.yazi = {
          enable = true;
          # Override shellWrapperName in private.nix if needed (default: "yy")
          shellWrapperName = "yy";
        };
        programs.zellij.enable = true;
      };
  };
}
