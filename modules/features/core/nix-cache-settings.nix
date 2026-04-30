{ ... }:
{
  flake.modules.nixos.nix-cache-settings =
    { ... }:
    {
      # Centralized external binary caches. Import this only on hosts that benefit
      # from these desktop/dev upstream caches.
      nix.settings = {
        extra-substituters = [
          "https://cache.numtide.com"
          "https://devenv.cachix.org"
          "https://nixpkgs-python.cachix.org"
          "https://catppuccin.cachix.org"
          "https://zed-industries.cachix.org"
          "https://hyprland.cachix.org"
        ];
        extra-trusted-public-keys = [
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
          "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
          "zed-industries.cachix.org-1:fgVpvtdF+ssrgP1lB6EusuR3uM6bNcncWduKxri3u6Y="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };
}
