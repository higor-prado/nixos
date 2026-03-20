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
  repoExtraGroups = [
    "video"
    "audio"
    "input"
    "docker"
    "rfkill"
    "uinput"
    "linuwu_sense"
  ];
  extraGroups = primaryUserGroups ++ repoExtraGroups;
  privateModule = ../../private/users/higorprado/default.nix;
in
{
  repo.users.higorprado = {
    inherit userName homeDirectory primaryGroup homeStateVersion extraGroups privateModule;
    shell = "fish";
    isPrimary = true;
  };

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
