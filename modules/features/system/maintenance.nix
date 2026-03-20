{ ... }:
{
  flake.modules.nixos.maintenance =
    { ... }:
    {
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
    };
}
