{ den, ... }:
{
  den.aspects.nix-settings = den.lib.parametric {
    includes = [
      (den.lib.take.exactly (
        { host, ... }:
        {
          nixos =
            { lib, ... }:
            {
              nix.settings.trusted-users = lib.mkForce (
                [ "root" ]
                ++ builtins.attrNames host.users
              );
            };
        }
      ))
    ];

    nixos =
      { ... }:
      {
        # Nix package manager settings
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          auto-optimise-store = true;
          substituters = [ "https://cache.numtide.com" ];
          trusted-public-keys = [
            "cache.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
          extra-substituters = [
            "https://devenv.cachix.org"
            "https://nixpkgs-python.cachix.org"
            "https://catppuccin.cachix.org"
            "https://zed-industries.cachix.org"
          ];
          extra-trusted-public-keys = [
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
            "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
            "zed-industries.cachix.org-1:fgVpvtdF+ssrgP1lB6EusuR3uM6bNcncWduKxri3u6Y="
          ];
        };

        # nh — easy Nix command wrapper with automatic generation management
        programs.nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
        };
      };
  };
}
