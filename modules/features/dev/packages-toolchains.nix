{ ... }:
{
  den.aspects.packages-toolchains.nixos =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        gcc
        nodejs
        sqlite
        tree-sitter
        binutils
        gnumake
        cmake
        libtool
      ];
    };
}
