{ ... }:
{
  flake.modules.nixos.nix-settings-desktop =
    { ... }:
    {
      nix.settings = {
        extra-substituters = [
          "https://devenv.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://catppuccin.cachix.org"
          "https://zed-industries.cachix.org"
          "https://hyprland.cachix.org"
          "https://noctalia.cachix.org"
        ];
        extra-trusted-public-keys = [
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
          "zed-industries.cachix.org-1:fgVpvtdF+ssrgP1lB6EusuR3uM6bNcncWduKxri3u6Y="
          "hyprland.cachix.org-1:7R1/of0Sur8cc4q8oZnCu30CwGR020BgxsRQgQhNj+4="
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    };
}