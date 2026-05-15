# Currently imported only by predator: smartd health monitoring.
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
