{ ... }:
{
  flake.modules.homeManager.dev-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        uv
        nixfmt
      ];
    };
}
