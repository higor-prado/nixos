{ ... }:
{
  den.aspects.networking-avahi.nixos =
    { ... }:
    {
      # mDNS for hostname.local resolution
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          addresses = true;
          userServices = true;
        };
      };
    };
}
