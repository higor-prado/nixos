{ config, lib, ... }:
let
  userName = config.username;
  homeDirectory = "/home/${userName}";
  homeStateVersion = "25.11";
  userExtraGroups = [
    "wheel"
    "networkmanager"
  ];
  privateModule = ../../private/users + "/${userName}/default.nix";
in
{
  options.username = lib.mkOption {
    type = lib.types.singleLineStr;
    readOnly = true;
    default = "higorprado";
    description = "Canonical tracked user name for repo-owned user modules.";
  };

  config = {
    flake.modules.nixos.higorprado =
      { pkgs, ... }:
      {
        users.groups.${userName} = { };
        users.users.${userName} = {
          isNormalUser = true;
          home = homeDirectory;
          group = userName;
          shell = pkgs.fish;
          extraGroups = userExtraGroups;
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
