{ lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  custom.host.role = "desktop";
}
