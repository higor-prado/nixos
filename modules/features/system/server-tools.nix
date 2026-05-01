{ ... }:
{
  flake.modules.nixos.server-tools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        btrfs-progs
        lsof
        strace
        bind
        mtr
        iperf3
        tcpdump
      ];
    };

  flake.modules.homeManager.server-tools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        yq-go
        ncdu
      ];
    };
}
