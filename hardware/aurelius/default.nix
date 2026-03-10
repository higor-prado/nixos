{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  # Host role (contract signal for validation scripts)
  custom.host.role = "server";

  # Bootloader configuration (systemd-boot with EFI)
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };
  boot.initrd.systemd.enable = true;

  # Host-specific metadata
  system.stateVersion = lib.mkForce "25.11";
}
