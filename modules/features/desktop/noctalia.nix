{ inputs, ... }:
{
  flake.modules = {
    nixos.noctalia =
      { ... }:
      {
        imports = [ inputs.noctalia.nixosModules.default ];
        services.noctalia-shell.enable = true;
      };

    homeManager.noctalia =
      { ... }:
      {
        imports = [ inputs.noctalia.homeModules.default ];
        programs.noctalia-shell.enable = true;
      };
  };
}
