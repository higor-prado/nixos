{ inputs, ... }:
{
  flake.modules.nixos.home-manager-settings =
    { ... }:
    {
      config.home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
        sharedModules = [ inputs.catppuccin.homeModules.catppuccin ];
      };
    };
}
