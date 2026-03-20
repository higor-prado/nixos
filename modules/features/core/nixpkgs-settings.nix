{ ... }:
{
  flake.modules.nixos.nixpkgs-settings =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;
    };

  den.aspects.nixpkgs-settings.nixos =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;
    };
}
