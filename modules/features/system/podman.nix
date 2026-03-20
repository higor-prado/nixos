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
}
