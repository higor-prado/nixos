{ den, ... }:
let
  userName = "higorprado";
  homeDirectory = "/home/higorprado";
  primaryGroup = "higorprado";
  homeStateVersion = "25.11";
  extraGroups = [
    "video"
    "audio"
    "input"
    "docker"
    "rfkill"
    "uinput"
    "linuwu_sense"
  ];
  privateModule = ../../private/users/higorprado/default.nix;
in
{
  repo.users.higorprado = {
    inherit userName homeDirectory primaryGroup homeStateVersion extraGroups privateModule;
    shell = "fish";
    isPrimary = true;
  };

  flake.modules.nixos.higorprado =
    { ... }:
    {
      users.groups.${primaryGroup} = { };
      users.users.${userName} = {
        isNormalUser = true;
        home = homeDirectory;
        group = primaryGroup;
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

  # User aspect for higorprado.
  # Den routes .homeManager to home-manager.users.higorprado on hosts
  # where this user has the "homeManager" class (see modules/hosts/predator.nix).
  den.aspects.higorprado = {
    includes = [
      den._.define-user
      den._.primary-user
      (den._.user-shell "fish") # programs.fish.enable + shell at OS and HM level
      den._.mutual-provider
    ];

    provides.predator =
      { user, ... }:
      {
        nixos.users.users.${user.userName}.extraGroups = [
          "video"
          "audio"
          "input"
          "docker"
          "rfkill"
          "uinput"
          "linuwu_sense"
        ];
      };

    nixos =
      { ... }:
      {
        users.users.higorprado = {
          # den._.define-user owns name/home/isNormalUser; this aspect keeps only
          # the repo-specific primary group wiring.
          group = primaryGroup;
        };
        users.groups.${primaryGroup} = { };
      };

    homeManager =
      { lib, ... }:
      {
        home.stateVersion = homeStateVersion;

        imports = lib.optional (builtins.pathExists privateModule) privateModule;
      };
  };
}
