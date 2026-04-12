{ ... }:
{
  flake.modules = {
    nixos.gaming =
      { pkgs, ... }:
      {
        boot.kernelModules = [ "ntsync" ];

        programs.steam = {
          enable = true;
          protontricks.enable = true;
          package = pkgs.steam.override {
            extraEnv = {
              GTK_IM_MODULE = "fcitx";
              SDL_IM_MODULE = "fcitx";
              XMODIFIERS = "@im=fcitx";
              PROTON_USE_NTSYNC = "1";
              PROTON_ENABLE_NVAPI = "1";
              # NVIDIA NGX — enables Proton's built-in NVIDIA RTX/DLSS updater,
              # so DLSS-FSR and other NGX features stay current in Proton prefixes.
              PROTON_ENABLE_NGX_UPDATER = "1";
            };
          };
          extraPackages = [ pkgs.fcitx5-gtk ];
        };

        programs.gamemode = {
          enable = true;
          settings.general = {
            desiredgov = "performance";
            inhibit_screensaver = 1;
            renice = 10;
            softrealtime = "auto";
          };
        };
      };

    homeManager.gaming =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mangohud ];
      };
  };
}
