{ ... }:
{
  flake.modules = {
    nixos.mosh =
      { ... }:
      {
        programs.mosh.enable = true;
      };

    homeManager.mosh =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mosh ];
      };
  };
}
