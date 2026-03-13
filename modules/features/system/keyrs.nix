{ den, ... }:
{
  den.aspects.keyrs = den.lib.parametric {
    nixos =
      { ... }:
      {
        hardware.uinput.enable = true;
        services.keyrs.enable = true;
      };
  };
}
