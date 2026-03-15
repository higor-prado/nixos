{ ... }:
{
  den.aspects.maintenance.nixos =
    { ... }:
    {
      # SSD maintenance - TRIM timer
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
    };
}
