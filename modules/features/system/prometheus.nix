{ ... }:
{
  flake.modules.nixos.prometheus =
    { ... }:
    {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9090 ];

      services.prometheus = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9090;
        globalConfig.scrape_interval = "15s";
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "127.0.0.1:9100" ];
              }
            ];
          }
        ];
      };
    };
}
