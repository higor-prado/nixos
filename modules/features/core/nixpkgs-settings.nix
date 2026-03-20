{ ... }:
{
  flake.modules.nixos.nixpkgs-settings =
    { ... }:
    {
      nixpkgs.config.allowUnfree = true;
    };
}
