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

      # Fix Neovim server socket permissions: increase systemd user session limits
      # Without this, LSP servers fail with "Failed to start server: operation not permitted"
      # when creating Unix sockets in /run/user/1000/nvim.*
      security.pam.services.systemd-user = {
        limits = [
          # Increase file descriptor limit (default 1024 is too low for LSP servers)
          { domain = "*"; item = "nofile"; type = "-"; value = "65536"; }
          # Increase process limit (prevents fork failures)
          { domain = "*"; item = "nproc"; type = "-"; value = "4096"; }
        ];
      };
    };
}
