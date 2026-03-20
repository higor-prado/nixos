{ lib, ... }:
{
  options.repo = {
    hosts = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              system = lib.mkOption {
                type = lib.types.str;
              };
              role = lib.mkOption {
                type = lib.types.enum [
                  "desktop"
                  "server"
                ];
              };
              trackedUsers = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
              llmAgents = lib.mkOption {
                type = lib.types.raw;
                default = {
                  homePackages = [ ];
                  systemPackages = [ ];
                };
              };
            };
          }
        )
      );
    };

    users = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              userName = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              homeDirectory = lib.mkOption {
                type = lib.types.str;
                default = "/home/${name}";
              };
              primaryGroup = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              homeStateVersion = lib.mkOption {
                type = lib.types.str;
              };
              shell = lib.mkOption {
                type = lib.types.str;
                default = "bash";
              };
              isPrimary = lib.mkOption {
                type = lib.types.bool;
                default = false;
              };
              extraGroups = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
              };
              privateModule = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
              };
            };
          }
        )
      );
    };
  };
}
