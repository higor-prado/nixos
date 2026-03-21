{ ... }:
let
  userName = "higorprado";
  homeDirectory = "/home/higorprado";
  primaryGroup = "higorprado";
  homeStateVersion = "25.11";
  primaryUserGroups = [
    "wheel"
    "networkmanager"
  ];
  extraGroups = primaryUserGroups;
  privateModule = ../../private/users/higorprado/default.nix;
in
{
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
}
