{ ... }:
{
  flake.modules.nixos.packages-docs-tools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        ghostscript
        tectonic
        mermaid-cli
        pandoc
      ];
    };

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
