{ ... }:
{
  den.aspects.networking-resolved.nixos =
    { ... }:
    {
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved = {
        enable = true;
        settings.Resolve.DNSSEC = "allow-downgrade";
        # Avoid running two mDNS responders at the same time (resolved + avahi).
        settings.Resolve.MulticastDNS = false;
      };
    };
}
