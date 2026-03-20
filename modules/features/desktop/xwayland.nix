{ ... }:
{
  flake.modules.nixos.xwayland =
    { ... }:
    { programs.xwayland.enable = true; };

  den.aspects.xwayland.nixos =
    { ... }:
    { programs.xwayland.enable = true; };
}
