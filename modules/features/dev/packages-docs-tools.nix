{ ... }:
{
  flake.modules.homeManager.packages-docs-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        ghostscript
        tectonic
        mermaid-cli
        pandoc
      ];
    };
}
