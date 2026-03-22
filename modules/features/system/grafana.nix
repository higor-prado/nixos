{ ... }:
{
  flake.modules.nixos.grafana =
    { lib, pkgs, ... }:
    {
      # Generate a persistent secret key on first activation if absent.
      # The file is owned by grafana and not tracked anywhere — it survives
      # rebuilds as long as /var/lib/grafana is preserved.
      system.activationScripts.grafana-secret-key = lib.stringAfter [ "users" "groups" ] ''
        keyFile=/var/lib/grafana/secret-key
        if [ ! -f "$keyFile" ]; then
          mkdir -p /var/lib/grafana
          ${pkgs.openssl}/bin/openssl rand -base64 32 > "$keyFile"
          chown grafana:grafana "$keyFile"
          chmod 600 "$keyFile"
        fi
      '';

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3001 ];

      services.grafana = {
        enable = true;

        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3001;
            domain = "aurelius.your-tailnet.ts.net";
            root_url = "http://aurelius.your-tailnet.ts.net:3001/";
          };

          security.secret_key = "$__file{/var/lib/grafana/secret-key}";

          auth.disable_login_form = true;

          "auth.anonymous" = {
            enabled = true;
            org_name = "Main Org.";
            org_role = "Viewer";
          };

          users = {
            allow_sign_up = false;
            viewers_can_edit = false;
          };
        };

        provision = {
          enable = true;
          datasources.settings = {
            apiVersion = 1;
            datasources = [
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:9090";
                isDefault = true;
                editable = false;
              }
            ];
          };
        };
      };
    };
}
