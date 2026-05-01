{ ... }:
{
  flake.modules.homeManager.editors-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor-fhs ];
    };
}
