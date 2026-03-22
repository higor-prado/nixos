{ ... }:
{
  flake.modules = {
    nixos.mosh =
      { ... }:
      {
        programs.mosh.enable = true;
        networking.firewall.interfaces.tailscale0.allowedUDPPortRanges = [
          {
            from = 60000;
            to = 61000;
          }
        ];
      };

    homeManager.mosh =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.mosh ];
      };
  };
}
