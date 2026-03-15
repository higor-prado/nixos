{ ... }:
{
  den.aspects.nixpkgs-settings.nixos =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;
    };
}
