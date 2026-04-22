{ config, pkgs, ... }:
{
  services.lact.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    # NVIDIA open kernel module. Supported on RTX 4060 (Ada) since driver 560+.
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    dynamicBoost.enable = false;
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "gtk3";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  environment.etc."nvidia/nvidia-application-profiles-rc.d/50-wayland-vram-fix.json".text =
    builtins.toJSON
      {
        rules = [
          {
            pattern = {
              feature = "procname";
              matches = "niri";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          {
            pattern = {
              feature = "procname";
              matches = ".quickshell-wra";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          {
            pattern = {
              feature = "procname";
              matches = "code";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          # xwayland-satellite and Xwayland hold leaked VRAM buffers
          # that are never freed. On 8GB cards this is critical.
          {
            pattern = {
              feature = "procname";
              matches = "xwayland-satell";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
          {
            pattern = {
              feature = "procname";
              matches = "Xwayland";
            };
            profile = "Limit Free Buffer Pool On Wayland Compositors";
          }
        ];

        profiles = [
          {
            name = "Limit Free Buffer Pool On Wayland Compositors";
            settings = [
              {
                key = "GLVidHeapReuseRatio";
                value = 0;
              }
            ];
          }
        ];
      };
}
