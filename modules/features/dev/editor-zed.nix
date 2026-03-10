{ ... }:
{
  den.aspects.editor-zed = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.zed-editor-fhs ];
      };
  };
}
