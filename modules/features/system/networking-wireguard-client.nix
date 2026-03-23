{ ... }:
{
  flake.modules.nixos.networking-wireguard-client =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wireguard-tools ];

      boot.extraModulePackages = [ ];
      networking.firewall.checkReversePath = "loose";

      # Disable IPv6 globally while any WireGuard tunnel is active via NM,
      # preventing IPv6 traffic from bypassing the VPN (happy eyeballs leak).
      networking.networkmanager.dispatcherScripts = [
        {
          source = pkgs.writeShellScript "wireguard-ipv6-toggle" ''
            case "$1" in
              wg-*)
                case "$2" in
                  up)   ${pkgs.procps}/bin/sysctl -qw net.ipv6.conf.all.disable_ipv6=1 ;;
                  down) ${pkgs.procps}/bin/sysctl -qw net.ipv6.conf.all.disable_ipv6=0 ;;
                esac
                ;;
            esac
          '';
          type = "basic";
        }
      ];
    };
}
