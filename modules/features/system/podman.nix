{ ... }:
{
  flake.modules = {
    nixos.podman =
      { ... }:
      {
        virtualisation.podman = {
          enable = true;
          dockerCompat = false;
        };
      };

    homeManager.podman =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.distrobox ];
      };
  };
}
