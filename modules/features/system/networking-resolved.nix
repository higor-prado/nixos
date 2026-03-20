{ ... }:
{
  flake.modules.nixos.networking-resolved =
    { ... }:
    {
      networking.networkmanager.dns = "systemd-resolved";
      services.resolved = {
        enable = true;
        settings.Resolve.DNSSEC = "allow-downgrade";
        settings.Resolve.MulticastDNS = false;
      };
    };
}
