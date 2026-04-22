{ ... }:
{
  flake.modules.homeManager.attic-client =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.attic-client ];

      # Concrete substituter endpoint and trusted key stay in the host's private
      # override via nix.settings.extra-substituters and
      # nix.settings.extra-trusted-public-keys.
    };
}
