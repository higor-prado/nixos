{ ... }:
{
  den.aspects.editor-zed = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.zed-editor-fhs ];
      };
  };
}
