{ den, ... }:
{
  den.aspects.docker = den.lib.parametric {
    includes = [
      ({ user, ... }: {
        nixos.users.users.${user.userName}.extraGroups = [ "docker" ];
      })
    ];

    nixos =
      { ... }:
      {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };
      };
  };
}
