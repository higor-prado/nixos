{ ... }:
{
  den.aspects.security.nixos =
    { ... }:
    {
      # Firewall - allow SSH only
      networking.firewall.enable = true;
      networking.firewall.allowedTCPPorts = [ 22 ];

      # Sudo configuration
      security.sudo.wheelNeedsPassword = true;
    };
}
