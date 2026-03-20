{ ... }:
{
  flake.modules.nixos.networking =
    { ... }:
    {
      networking.networkmanager.enable = true;
      users.groups.netdev = { };
    };
}
