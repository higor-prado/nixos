{ ... }:
{
  flake.modules.nixos.networking-avahi =
    { ... }:
    {
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
