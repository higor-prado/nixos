{ ... }:
{
  flake.modules.nixos.upower =
    { ... }:
    { services.upower.enable = true; };

  den.aspects.upower.nixos =
    { ... }:
    { services.upower.enable = true; };
}
