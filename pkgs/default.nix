{ pkgs, inputs }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Local derivations
  linuwu-sense = pkgs.callPackage ./linuwu-sense.nix { };
  predator-tui = pkgs.callPackage ./predator-tui.nix { };

  dms-awww = pkgs.callPackage ./dms-awww.nix { src = inputs."dms-awww-src"; };
  catppuccin-zen-browser = pkgs.callPackage ./catppuccin-zen-browser.nix {
    src = inputs."catppuccin-zen-browser-src";
  };

  # Upstream flake packages
  rmpc = inputs.rmpc.packages.${system}.default;
  spotatui = inputs.spotatui.packages.${system}.default;
}
