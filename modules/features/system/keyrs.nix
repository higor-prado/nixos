{ ... }:
{
  flake.modules.nixos.keyrs =
    { ... }:
    {
      hardware.uinput.enable = true;
      services.keyrs.enable = true;
    };
}
