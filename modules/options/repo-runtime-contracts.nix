{ lib, inputs, ... }:
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
          description = "Selected tracked user for the concrete host runtime.";
        };

        config.home-manager.sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
      };
  };
}
