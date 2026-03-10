{ den, ... }:
{
  # User aspect for higorprado.
  # Den routes .homeManager to home-manager.users.higorprado on hosts
  # where this user has the "homeManager" class (see modules/hosts/predator.nix).
  den.aspects.higorprado = {
    includes = [
      den._.define-user
      den._.primary-user
      (den._.user-shell "fish")  # programs.fish.enable + shell at OS and HM level
    ];

    nixos =
      { ... }:
      {
        users.users.higorprado = {
          # den._.define-user owns name/home/isNormalUser; this aspect keeps only
          # the repo-specific primary group wiring.
          group = "higorprado";
        };
        users.groups.higorprado = { };
      };

    homeManager =
      { lib, ... }:
      {
        home.stateVersion = "25.11";

        imports = lib.optional (builtins.pathExists ../../home/base/private.nix) ../../home/base/private.nix;
      };
  };
}
