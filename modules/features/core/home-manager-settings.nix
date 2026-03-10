{ ... }:
{
  den.aspects.home-manager-settings.nixos =
    { ... }:
    {
      config.home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
      };
    };
}
