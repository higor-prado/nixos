{ ... }:
{
  # Concrete Aurelius owner: Attic server + bootstrap for the local aurelius cache.
  flake.modules.nixos.aurelius-attic-server =
    {
      lib,
      pkgs,
      ...
    }:
    let
      environmentFile = "/etc/atticd/atticd.env";
      atticClient = lib.getExe' pkgs.attic-client "attic";
      atticAdmin = "/run/current-system/sw/bin/atticd-atticadm";
      bootstrapScript = pkgs.writeShellScript "attic-cache-bootstrap" ''
        set -euo pipefail

        export HOME=/var/lib/attic-publisher
        export XDG_CONFIG_HOME=/var/lib/attic-publisher/.config
        mkdir -p "$HOME" "$XDG_CONFIG_HOME"

        token="$(${atticAdmin} make-token --sub attic-publisher --validity 1y --create-cache 'aurelius' --pull 'aurelius' --push 'aurelius')"

        ${atticClient} login --set-default local http://127.0.0.1:8080 "$token" >/dev/null

        if ! ${atticClient} cache info local:aurelius >/dev/null 2>&1; then
          ${atticClient} cache create --public local:aurelius
        fi
      '';
    in
    {
      config = {
        networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8080 ];

        services.atticd = {
          enable = true;
          inherit environmentFile;
          settings = {
            listen = "0.0.0.0:8080";
            database.url = "sqlite:///var/lib/atticd/server.db?mode=rwc";
            storage = {
              type = "local";
              path = "/var/lib/atticd/storage";
            };
          };
        };

        systemd.services.attic-cache-bootstrap = {
          description = "Bootstrap the aurelius Attic cache";
          after = [
            "atticd.service"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = environmentFile;
            ExecStart = bootstrapScript;
            StateDirectory = "attic-publisher";
          };
        };
      };
    };
}
