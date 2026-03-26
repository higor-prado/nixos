{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # NVMe root — UUID do nvme0n1p2 (label NIXOS_SD é do build de imagem)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/14e19a7b-0ae0-484d-9d54-43bd6fdc20c7";
    fsType = "ext4";
  };

  # Partição de firmware U-Boot (nvme0n1p1)
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "nofail" "noauto" ];
  };

  # HDD Seagate 2 TB para dados
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/e47efc1f-98d8-42ab-80e1-d0e29115e6e0";
    fsType = "ext4";
    options = [ "nofail" "noatime" "lazytime" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
