{ ... }:
{
  den.aspects.networking.nixos =
    { ... }:
    {
      # NetworkManager
      networking.networkmanager.enable = true;

      # Some D-Bus policy fragments reference the legacy "netdev" group.
      # Defining it avoids runtime warning spam on hosts where this group is absent.
      users.groups.netdev = { };
    };
}
