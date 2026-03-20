{ ... }:
{
  flake.modules.nixos.home-manager-settings =
    { ... }:
    {
      config.home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
      };
    };

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
