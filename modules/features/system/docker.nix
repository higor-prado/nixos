{ den, ... }:
{
  den.aspects.docker = den.lib.parametric {
    nixos =
      { ... }:
      {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      };
  };
}
