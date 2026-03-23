{ ... }:
{
  flake.modules.nixos.attic-publisher =
    { lib, pkgs, ... }:
    let
      atticClient = lib.getExe' pkgs.attic-client "attic";
      configFile = "/etc/attic/publisher.conf";
      postBuildHookScript = pkgs.writeShellScript "attic-post-build-hook" ''
        set -euo pipefail
        [ -f ${lib.escapeShellArg configFile} ] || exit 0
        # shellcheck source=/dev/null
        source ${lib.escapeShellArg configFile}

        export HOME=/var/lib/attic-publisher
        export XDG_CONFIG_HOME=/var/lib/attic-publisher/.config
        mkdir -p "$HOME" "$XDG_CONFIG_HOME"

        token="$(cat "$TOKEN_FILE")"

        ${atticClient} login --set-default remote "$ENDPOINT" "$token" >/dev/null 2>&1
        if ! ${atticClient} push "remote:$CACHE" $OUT_PATHS; then
          echo "attic post-build push failed for remote:$CACHE" >&2
        fi
      '';
    in
    {
      config = {
        systemd.tmpfiles.rules = [
          "d /var/lib/attic-publisher 0700 root root -"
          "d /var/lib/attic-publisher/.config 0700 root root -"
        ];

        nix.settings.post-build-hook = postBuildHookScript;
      };
    };
}
