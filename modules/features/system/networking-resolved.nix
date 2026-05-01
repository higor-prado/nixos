{ ... }:
{
  flake.modules.nixos.networking-resolved =
    { ... }:
    {
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved = {
        enable = true;
        settings.Resolve.DNSSEC = "no";
        settings.Resolve.MulticastDNS = false;
      };
    };
}
