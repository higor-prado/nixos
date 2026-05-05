{ ... }:
{
  flake.modules.nixos.bifrost =
    { pkgs, ... }:
    let
      dataDir = "/var/lib/bifrost";
      envFile = "/etc/bifrost/bifrost.env";
      port = 8081;
      configDir = "/etc/tailscale-serve";
      configFileJson = "${configDir}/bifrost-svc.json";
    in
    {
      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 root root -"
        "d ${configDir} 0755 root root -"
      ];

      virtualisation.oci-containers.containers.bifrost = {
        image = "maximhq/bifrost:latest";
        ports = [ "127.0.0.1:${toString port}:8080" ];
        environmentFiles = [ envFile ];
        volumes = [ "${dataDir}:/app/data" ];
        autoStart = true;
      };

      # Tailscale Service: expose bifrost as HTTPS on its own service subdomain.
      # set-config manages svc:<name> subdomains that are independent of the
      # device domain, so this doesn't conflict with aiostreams' serve route.
      systemd.services.tailscale-serve-bifrost = {
        description = "Tailscale Serve: bifrost HTTPS proxy (svc:bifrost)";
        after = [ "tailscaled.service" ];
        wants = [ "tailscaled.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [ pkgs.tailscale ];
        script = ''
          install -Dm644 -T <(cat <<'SVCEOF'
          {
            "TCP": {
              "443": {
                "HTTPS": {
                  "svc:bifrost": {
                    "Handlers": {
                      "/": {
                        "Proxy": "http://127.0.0.1:${toString port}"
                      }
                    }
                  }
                }
              }
            }
          }
          SVCEOF
          ) "${configFileJson}"
          tailscale serve set-config --all "${configFileJson}"
        '';
      };
    };
}
