{ den, ... }:
{
  den.aspects.bluetooth = den.lib.parametric {
    nixos =
      { ... }:
      {
        hardware.bluetooth.enable = true;
      };
  };
}
