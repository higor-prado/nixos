{ ... }:
{
  flake.modules.nixos.system-tools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
      ];
    };
}
