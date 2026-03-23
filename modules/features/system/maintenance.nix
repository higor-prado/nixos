{ ... }:
{
  flake.modules.nixos.maintenance =
    { pkgs, ... }:
    {
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };

    };
}
