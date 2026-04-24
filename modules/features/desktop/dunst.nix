{ ... }:
{
  flake.modules.homeManager.dunst =
    { lib, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
    in
    {
      services.dunst.enable = true;

      # Neutralize the immutable dunstrc that services.dunst.enable creates.
      # The copy-once activation script provisions a mutable replacement.
      xdg.configFile."dunst/dunstrc".enable = lib.mkForce false;

      home.activation.provisionDunstConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/dunst/dunstrc;
          target = "$HOME/.config/dunst/dunstrc";
        }
      );
    };
}
