{ ... }:
{
  flake.modules.nixos.attic-client =
    { config, lib, ... }:
    let
      cacheEndpoint = config.custom.attic.client.endpoint;
      publicKey = config.custom.attic.client.publicKey;
    in
    {
      options.custom.attic.client = {
        endpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Private Attic substituter endpoint for this host.";
        };

        publicKey = lib.mkOption {
          type = lib.types.nullOr lib.types.singleLineStr;
          default = null;
          description = "Trusted public key for the private Attic substituter.";
        };
      };

      config = lib.mkMerge [
        {
          assertions = [
            {
              assertion = (cacheEndpoint == null) == (publicKey == null);
              message = "custom.attic.client.endpoint and custom.attic.client.publicKey must be set together.";
            }
          ];
        }
        (lib.mkIf (cacheEndpoint != null) {
          nix.settings = {
            extra-substituters = [ cacheEndpoint ];
            extra-trusted-public-keys = [ publicKey ];
          };
        })
      ];
    };
}
