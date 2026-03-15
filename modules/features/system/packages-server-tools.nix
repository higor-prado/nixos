{ ... }:
{
  den.aspects.packages-server-tools.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        eza
        bat
        fd
        ripgrep
        jq
        yq-go
        tmux
        btop
        ncdu
        lsof
        strace
        bind
        mtr
        iperf3
        tcpdump
      ];
    };
}
