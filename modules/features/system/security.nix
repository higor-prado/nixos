{ ... }:
{
  flake.modules.nixos.security =
    { ... }:
    {
      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 ];

      security.sudo.wheelNeedsPassword = true;
    };
}
