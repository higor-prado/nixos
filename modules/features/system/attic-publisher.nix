{ ... }:
{
  flake.modules.nixos.attic-publisher =
    { lib, pkgs, ... }:
    let
      atticClient = lib.getExe' pkgs.attic-client "attic";
      configFile = "/etc/attic/publisher.conf";
    in
    {
      # Hook reads ENDPOINT, CACHE, TOKEN_FILE from /etc/attic/publisher.conf at runtime.
      # Create that file in private/hosts/<host>/services.nix.
      nix.settings.post-build-hook = pkgs.writeShellScript "attic-post-build-hook" ''
        set -euo pipefail
        [ -f ${lib.escapeShellArg configFile} ] || exit 0
        # shellcheck source=/dev/null
        source ${lib.escapeShellArg configFile}
        export HOME=/var/lib/attic-publisher
        export XDG_CONFIG_HOME=/var/lib/attic-publisher/.config
        mkdir -p "$HOME" "$XDG_CONFIG_HOME"
        token="$(cat "$TOKEN_FILE")"
        ${atticClient} login --set-default remote "$ENDPOINT" "$token" >/dev/null 2>&1
        ${atticClient} push remote:"$CACHE" $OUT_PATHS 2>/dev/null || true
      '';
    };
}
