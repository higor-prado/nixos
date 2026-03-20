{ ... }:
{
  flake.modules.homeManager.dev-tools =
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

  den.aspects.dev-tools = {
    provides.to-users.homeManager =
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
