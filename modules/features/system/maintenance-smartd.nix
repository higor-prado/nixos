{ ... }:
{
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
