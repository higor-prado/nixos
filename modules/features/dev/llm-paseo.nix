{ inputs, ... }:
{
  flake.modules.homeManager.llm-paseo =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
}
