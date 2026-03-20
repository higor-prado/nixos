{ ... }:
{
  flake.modules.homeManager.editor-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor-fhs ];
    };
}
