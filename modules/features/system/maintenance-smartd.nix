# Concrete Predator owner: smartd health monitoring (desktop-only).
{ ... }:
{
  flake.modules.nixos.maintenance-smartd =
    { ... }:
    {
      services.smartd = {
        enable = true;
        autodetect = true;
      };
    };
}
