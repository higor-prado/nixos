{ ... }:
{
  flake.modules.nixos.attic-publisher =
    { config, lib, pkgs, ... }:
    let
      endpoint = config.custom.attic.publisher.endpoint;
      cache = config.custom.attic.publisher.cache;
      tokenFile = config.custom.attic.publisher.tokenFile;
      atticClient = lib.getExe' pkgs.attic-client "attic";
      watchStoreScript = pkgs.writeShellScript "attic-watch-store-remote" ''
        set -euo pipefail

        export HOME=/var/lib/attic-publisher
        export XDG_CONFIG_HOME=/var/lib/attic-publisher/.config
        mkdir -p "$HOME" "$XDG_CONFIG_HOME"

        token="$(cat ${lib.escapeShellArg tokenFile})"

        ${atticClient} login --set-default remote ${lib.escapeShellArg endpoint} "$token" >/dev/null
        exec ${atticClient} watch-store remote:${lib.escapeShellArg cache}
      '';
    in
    {
      options.custom.attic.publisher = {
        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Private Attic API endpoint used by automatic publishers.";
        };

        cache = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Remote Attic cache name used by the publisher.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Path to a private token file used by the automatic Attic publisher.";
        };
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion =
                let
                  allUnset = endpoint == null && cache == null && tokenFile == null;
                  allSet = endpoint != null && cache != null && tokenFile != null;
                in
                allUnset || allSet;
              message = "custom.attic.publisher.endpoint, cache, and tokenFile must be set together.";
            }
          ];
        }
        (lib.mkIf (endpoint != null) {
          systemd.services.attic-watch-store = {
            description = "Watch the local Nix store and publish new paths to the remote Attic cache";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = watchStoreScript;
              Restart = "always";
              RestartSec = "10s";
              StateDirectory = "attic-publisher";
            };
          };
        })
      ];
    };
}
