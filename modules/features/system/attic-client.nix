{ ... }:
{
  flake.modules.nixos.attic-client = { ... }: {
    # Substituter endpoint and trusted public key are private.
    # Set nix.settings.extra-substituters and nix.settings.extra-trusted-public-keys
    # in private/hosts/<host>/services.nix.
  };
}
