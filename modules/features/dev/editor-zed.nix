{ ... }:
{
  flake.modules.homeManager.editor-zed =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zed-editor-fhs ];
    };

  den.aspects.editor-zed = {
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.zed-editor-fhs ];
      };
  };
}
