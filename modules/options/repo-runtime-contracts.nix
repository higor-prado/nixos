{ lib, inputs, ... }:
let
  mkRepoContextOptions =
    { lib, ... }:
    {
      options.repo.context = {
        hostName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        host = lib.mkOption {
          type = lib.types.nullOr lib.types.raw;
          default = null;
        };
        userName = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        user = lib.mkOption {
          type = lib.types.nullOr lib.types.raw;
          default = null;
        };
      };
    };
in
{
  flake.modules = {
    nixos.repo-runtime-contracts =
      { lib, ... }:
      {
        options.custom.host.role = lib.mkOption {
          type = lib.types.enum [
            "desktop"
            "server"
          ];
          default = "desktop";
          description = "Repo-local runtime host role contract for the dendritic shadow path.";
        };

        options.custom.user.name = lib.mkOption {
          type = lib.types.str;
          default = "user";
          description = "Repo-local compatibility username bridge for the dendritic shadow path.";
        };

        config.home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
      };

    nixos.repo-context = mkRepoContextOptions;
    homeManager.repo-context = mkRepoContextOptions;
  };
}
