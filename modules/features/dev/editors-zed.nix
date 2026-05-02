{ ... }:
{
  flake.modules.homeManager.editors-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor ];

      programs.fish.shellAbbrs = {
        zed = "uwsm-app zeditor";
      };
    };
}
