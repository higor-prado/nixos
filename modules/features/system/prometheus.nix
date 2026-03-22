{ ... }:
{
  flake.modules.nixos.prometheus =
    { ... }:
    {
      services.prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
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
