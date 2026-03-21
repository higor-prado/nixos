{ ... }:
{
  flake.modules.nixos.networking-wireguard-client =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.wireguard-tools ];

      boot.extraModulePackages = [ ];
      networking.firewall.checkReversePath = "loose";
    };
}
