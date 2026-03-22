{ ... }:
{
  flake.modules.nixos.grafana =
    { ... }:
    {
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
