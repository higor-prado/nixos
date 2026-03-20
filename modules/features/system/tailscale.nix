{ ... }:
{
  flake.modules.nixos.tailscale =
    { ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
      };
    };

  den.aspects.tailscale.nixos =
    { ... }:
    {
      services.tailscale = {
        enable = true;
        openFirewall = true;
      };
    };
}
