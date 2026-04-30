{ ... }:
{
  flake.modules.nixos.podman =
    { ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };
    };

  flake.modules.homeManager.podman =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.distrobox ];
    };
}
