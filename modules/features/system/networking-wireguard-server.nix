{ ... }:
{
  flake.modules.nixos.networking-wireguard-server =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wireguard-tools ];

      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv4.conf.all.src_valid_mark" = 1;
      };

      networking.firewall.checkReversePath = "loose";
    };
}
