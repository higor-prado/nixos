{ ... }:
{
  flake.modules.homeManager.desktop-viewers =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        loupe
        papers
      ];
    };
}
