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
    ./performance.nix
    ./impermanence.nix
    ./root-reset.nix
  ]
  ++ lib.optional (builtins.pathExists ../../private/hosts/predator/default.nix) ../../private/hosts/predator/default.nix;

}
