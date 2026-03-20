{ lib, ... }:
{
  options = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "user";
      description = "Canonical tracked user name for repo-owned user modules.";
    };

    repo.hosts = lib.mkOption {
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
            };
          }
        )
      );
    };
  };
}
