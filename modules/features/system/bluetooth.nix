{ ... }:
{
  flake.modules.nixos.bluetooth =
    { ... }:
    {
      hardware.bluetooth.enable = true;
    };

  den.aspects.bluetooth = {
    nixos =
      { ... }:
      {
        hardware.bluetooth.enable = true;
      };
  };
}
