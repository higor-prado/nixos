{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./performance.nix
  ]
  ++ lib.optional (builtins.pathExists ../../private/hosts/aurelius/default.nix) ../../private/hosts/aurelius/default.nix;

  # Bootloader configuration (systemd-boot with EFI)
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
  boot.initrd.systemd.enable = true;

}
