{ lib, ... }:
{
  imports = lib.optional (builtins.pathExists ./private.nix) ./private.nix;

  custom.host.role = "server";

  # Eval/build-focused skeleton defaults.
  boot.isContainer = true;
  networking.useHostResolvConf = lib.mkForce false;
  nixpkgs.config.allowUnfree = true;
}
