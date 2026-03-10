{ ... }:
{
  den.aspects.packages-docs-tools.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        ghostscript
        tectonic
        mermaid-cli
        pandoc
      ];
    };
}
