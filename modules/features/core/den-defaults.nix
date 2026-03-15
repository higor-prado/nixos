{ den, ... }:
{
  den.default.includes = with den.aspects; [
    den._.hostname
    user-context
    host-contracts
    system-base
    networking
    security
    keyboard
    nixpkgs-settings
    nix-settings
    maintenance
    tailscale
  ];
}
