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

  den.aspects.maintenance-smartd.nixos =
    { ... }:
    {
      # SSD Health Monitoring
      services.smartd = {
        enable = true;
        autodetect = true;
      };
    };
}
