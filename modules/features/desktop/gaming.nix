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
              PROTON_USE_NTSYNC = "1";
              PROTON_ENABLE_NVAPI = "1";
              # Auto-update DLSS DLLs to latest version. Newer DLLs have
              # better memory management (critical on 8GB VRAM budget).
              # NOTE: DLSS Frame Generation is not implemented in Proton;
              # only Super Resolution benefits from updated NGX DLLs.
              PROTON_ENABLE_NGX_UPDATER = "1";
              # Force upload heaps to system RAM instead of host-visible VRAM.
              # With ReBAR active (BAR1=8GB), VKD3D defaults to putting upload
              # heaps in VRAM, which eats into the rendering budget on 8GB cards.
              # NVIDIA Linux Vulkan driver already uses ~2x VRAM vs Windows
              # (forums.developer.nvidia.com/t/vram-allocation-issues/239678),
              # so reclaiming upload heap space is critical.
              VKD3D_CONFIG = "no_upload_hvv";
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
          pkgs.steam-tui
        ];
      };
  };
}
