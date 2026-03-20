{ ... }:
{
  flake.modules.nixos.podman =
    { pkgs, ... }:
    {
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };

      environment.systemPackages = [ pkgs.distrobox ];
    };

  den.aspects.podman.nixos =
    { pkgs, ... }:
    {
      # Podman (Docker alternative, rootless by default)
      virtualisation.podman = {
        enable = true;
        dockerCompat = false; # Keep Docker CLI bound to Docker daemon
      };

      # Distrobox for containerized development environments
      environment.systemPackages = [ pkgs.distrobox ];
    };
}
