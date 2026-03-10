{
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./hardware/gpu-nvidia.nix
    ./hardware/laptop-acer.nix
    ./hardware/peripherals-logi.nix
    ./hardware/audio-pipewire.nix
    ./hardware/encryption.nix
    ./boot.nix
    ./overlays.nix
    ./packages.nix
    ./performance.nix
  ]
  ++ lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  # Host role (contract signal for validation scripts)
  custom.host.role = "desktop";
}
