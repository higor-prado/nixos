{ ... }:
{
  den.aspects.dev-tools = {
    homeManager =
      { pkgs, ... }:
      {
        programs.bat.enable = true;
        programs.eza = {
          enable = true;
          enableFishIntegration = false;
        };

        home.packages = with pkgs; [
          gh
          jq
          fd
          tree
          sd
          uv
          nixfmt
        ];
      };
  };
}
