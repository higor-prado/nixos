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
