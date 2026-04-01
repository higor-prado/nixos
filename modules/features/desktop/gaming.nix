{ ... }:
{
  flake.modules = {
    nixos.gaming =
      { pkgs, ... }:
      {
        # Expose /dev/ntsync for Wine/Proton synchronization acceleration.
        boot.kernelModules = [ "ntsync" ];

        programs.steam = {
          enable = true;
          protontricks.enable = true;
          package = pkgs.steam.override {
            extraEnv = {
              GTK_IM_MODULE = "fcitx";
              SDL_IM_MODULE = "fcitx";
              XMODIFIERS = "@im=fcitx";
            };
          };
          extraPackages = [ pkgs.fcitx5-gtk ];
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

    homeManager.gaming =
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
