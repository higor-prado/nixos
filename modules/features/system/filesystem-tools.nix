{ ... }:
{
  den.aspects.packages-system-tools.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        # Filesystem tools
        btrfs-progs
      ];
    };
}
