{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./boot.nix
    ./performance.nix
  ]
  ++ lib.optional (builtins.pathExists ../../private/hosts/aurelius/default.nix) ../../private/hosts/aurelius/default.nix;

}
