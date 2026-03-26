{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./performance.nix
  ] ++ lib.optional (builtins.pathExists ../../private/hosts/cerebelo/default.nix)
       ../../private/hosts/cerebelo/default.nix;

  # extlinux (U-Boot) — RK3588S não usa EFI
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;
}
