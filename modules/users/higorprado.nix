{ config, lib, ... }:
let
  userName = config.username;
  homeDirectory = "/home/${userName}";
  primaryGroup = userName;
  homeStateVersion = "25.11";
  primaryUserGroups = [
    "wheel"
    "networkmanager"
  ];
  extraGroups = primaryUserGroups;
  privateModule = ../../private/users + "/${userName}/default.nix";
in
{
  options.username = lib.mkOption {
    type = lib.types.str;
    readOnly = true;
    default = "higorprado";
    description = "Canonical tracked user name for repo-owned user modules.";
  };

  config = {
    flake.modules.nixos.higorprado =
      { pkgs, ... }:
      {
        users.groups.${primaryGroup} = { };
        users.users.${userName} = {
          isNormalUser = true;
          home = homeDirectory;
          group = primaryGroup;
          shell = pkgs.fish;
          inherit extraGroups;
        };
      };

    flake.modules.homeManager.higorprado =
      { lib, ... }:
      {
        home = {
          username = userName;
          inherit homeDirectory;
          stateVersion = homeStateVersion;
        };

        imports = lib.optional (builtins.pathExists privateModule) privateModule;
      };
  };
}
