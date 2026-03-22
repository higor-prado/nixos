{ ... }:
{
  flake.modules.nixos.forgejo =
    { ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3000 ];

      services.forgejo = {
        enable = true;
        settings = {
          server = {
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = 3000;
            DOMAIN = "aurelius.your-tailnet.ts.net";
            ROOT_URL = "http://aurelius.your-tailnet.ts.net:3000/";
            DISABLE_SSH = true;
          };

          service.DISABLE_REGISTRATION = true;
          repository.DEFAULT_PRIVATE = "private";
        };
      };
    };
}
