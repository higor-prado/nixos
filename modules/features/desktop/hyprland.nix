{ inputs, ... }:
{
  flake.modules = {
    nixos.hyprland =
      { pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
      in
      {
        programs.hyprland = {
          enable = true;
          package = inputs.hyprland.packages.${system}.hyprland;
          xwayland.enable = true;
          withUWSM = false;
        };

        programs.hyprlock.enable = true;

      };

    homeManager.hyprland =
      { lib, ... }:
      let
        helpers = import ../../../lib/_helpers.nix;
        mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
      in
      {
        wayland.windowManager.hyprland = {
          enable = true;
          # user.conf is provisioned by the desktop composition module (e.g. hyprland-standalone.nix)
          extraConfig = "source = ~/.config/hypr/user.conf";
        };

        services.hypridle.enable = true;

        home.activation.provisionHypridleConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../../config/apps/hypridle/hypridle.conf;
            target = "$HOME/.config/hypr/hypridle.conf";
          }
        );
      };
  };
}
