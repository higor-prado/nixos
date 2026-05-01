{ ... }:
{
  flake.modules.homeManager.editors-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor-fhs ];

      programs.fish.shellAbbrs = {
        zed = "uwsm-app zeditor";
      };
    };
}
