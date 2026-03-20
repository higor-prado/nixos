{ ... }:
{
  flake.modules.nixos.packages-server-tools =
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
