{ ... }:
{
  den.aspects.gaming = {
    nixos =
      { pkgs, ... }:
      {
        programs.steam = {
          enable = true;
          protontricks.enable = true;
        };

        programs.gamemode = {
          enable = true;
          settings = {
            general = {
              desiredgov = "performance";
              inhibit_screensaver = 1;
              renice = 10;
              softrealtime = "auto";
            };
          };
        };

        programs.gamescope = {
          enable = true;
          capSysNice = true;
        };

        environment.systemPackages = [
          pkgs.mangohud
        ];
      };

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.goverlay
          pkgs.heroic
          pkgs.lutris
          pkgs.protonplus
          pkgs.steam-run
        ];
      };
  };
}
