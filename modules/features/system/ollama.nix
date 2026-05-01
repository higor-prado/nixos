{ ... }:
{
  flake.modules.nixos.ollama =
    { pkgs, ... }:
    {
      services.ollama = {
        enable = true;
        package = pkgs.ollama-cuda;
      };
    };

  flake.modules.homeManager.ollama =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.ollama-cuda ];
    };
}
