{ inputs, ... }:
{
  flake.modules = {
    nixos.noctalia =
      { lib, ... }:
      {
        services.upower.enable = lib.mkDefault true;
        services.power-profiles-daemon.enable = lib.mkDefault true;
      };

    homeManager.noctalia =
      { pkgs, ... }:
      {
        home.packages = [ inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      };
  };
}
