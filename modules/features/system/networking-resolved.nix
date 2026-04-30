_:
{
  flake.modules.nixos.networking-resolved =
    _:
    {
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved = {
        enable = true;
        settings.Resolve.DNSSEC = "no";
        settings.Resolve.MulticastDNS = false;
      };
    };
}
