{ ... }:
{
  den.aspects.media-cava = {
    provides.to-users.homeManager =
      { ... }:
      {
        programs.cava = {
          enable = true;
          settings = {
            general = {
              bars = 64;
              framerate = 60;
            };
            input = {
              method = "pulse";
              source = "auto";
            };
            output = {
              method = "ncurses";
              style = "stereo";
            };
            smoothing = {
              noise_reduction = 85;
              monstercat = 1;
              waves = 0;
              gravity = 120;
            };
            eq = {
              "1" = 0.8;
              "2" = 0.9;
              "3" = 1.0;
              "4" = 1.1;
              "5" = 1.2;
            };
          };
        };
      };
  };
}
