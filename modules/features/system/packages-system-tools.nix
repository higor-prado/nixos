{ ... }:
{
  flake.modules.nixos.packages-system-tools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Filesystem tools
        btrfs-progs
      ];
    };

  den.aspects.packages-system-tools.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Filesystem tools
        btrfs-progs
      ];
    };
}
