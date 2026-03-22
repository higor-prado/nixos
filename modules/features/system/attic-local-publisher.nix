{ ... }:
{
  flake.modules.nixos.attic-local-publisher =
    {
      lib,
      pkgs,
      ...
    }:
    let
      atticClient = lib.getExe' pkgs.attic-client "attic";
      atticAdmin = "/run/current-system/sw/bin/atticd-atticadm";
      watchStoreScript = pkgs.writeShellScript "attic-watch-store-local" ''
        set -euo pipefail

        export HOME=/var/lib/attic-publisher
        export XDG_CONFIG_HOME=/var/lib/attic-publisher/.config
        mkdir -p "$HOME" "$XDG_CONFIG_HOME"

        token="$(${atticAdmin} make-token --sub attic-publisher --validity 1y --pull 'aurelius' --push 'aurelius')"

        ${atticClient} login --set-default local http://127.0.0.1:8080 "$token" >/dev/null
        exec ${atticClient} watch-store local:aurelius
      '';
    in
    {
      config.systemd.services.attic-watch-store = {
        description = "Watch the Nix store and push new paths to the aurelius Attic cache";
        after = [
          "atticd.service"
          "attic-cache-bootstrap.service"
          "network-online.target"
        ];
        wants = [
          "attic-cache-bootstrap.service"
          "network-online.target"
        ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          EnvironmentFile = "/etc/atticd/atticd.env";
          ExecStart = watchStoreScript;
          Restart = "always";
          RestartSec = "10s";
          StateDirectory = "attic-publisher";
        };
      };
    };
}
