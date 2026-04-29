{ pkgs, inputs }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Local derivations
  linuwu-sense = pkgs.callPackage ./linuwu-sense.nix { };
  predator-tui = pkgs.callPackage ./predator-tui.nix { };

  catppuccin-zen-browser = pkgs.callPackage ./catppuccin-zen-browser.nix {
    src = inputs."catppuccin-zen-browser-src";
  };

  # Upstream flake packages
  rmpc = inputs.rmpc.packages.${system}.default;
}
