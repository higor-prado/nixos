{ ... }:
{
  flake.modules = {
    nixos.packages-server-tools =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          lsof
          strace
          bind
          mtr
          iperf3
          tcpdump
        ];
      };

    homeManager.packages-server-tools =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          yq-go
          ncdu
        ];
      };
  };
}
