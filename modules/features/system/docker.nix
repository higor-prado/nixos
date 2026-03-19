{ ... }:
{
  den.aspects.docker = {
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

    provides.to-users.homeManager =
      { ... }:
      {
        programs.fish.shellAbbrs = {
          dps = "docker ps";
          dpsa = "docker ps -a";
          di = "docker images";
          dex = "docker exec -it";
        };
      };
  };
}
