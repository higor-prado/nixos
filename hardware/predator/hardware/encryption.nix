{ ... }:
{
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = true;

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  boot.initrd.luks.devices = {
    "cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  };
}
