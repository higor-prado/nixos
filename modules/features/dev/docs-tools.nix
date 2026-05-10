{ ... }:
{
  flake.modules.homeManager.docs-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ghostscript
        tectonic
        pandoc
      ];
    };
}
