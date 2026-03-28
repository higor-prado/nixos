{ lib, ... }:
let
  storage = import ./storage-identifiers.nix;
in
{
  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/${storage.nvmeRootUuid}";
    fsType = lib.mkForce "ext4";
  };

  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-uuid/${storage.nvmeBootUuid}";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/${storage.dataUuid}";
    fsType = "ext4";
    options = [ "nofail" "noatime" "lazytime" ];
  };
}
