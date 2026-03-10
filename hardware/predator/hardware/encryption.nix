{ ... }:
{
  # Hibernation via btrfs swapfile on @swap subvolume inside cryptroot
  swapDevices = [ { device = "/swap/swapfile"; } ];
  boot.resumeDevice = "/dev/mapper/cryptroot";
  boot.kernelParams = [ "resume_offset=3738313" ];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  boot.initrd.luks.devices = {
    "cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
    "crypthome".crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
}
