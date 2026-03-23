{ config, inputs, ... }:
let
  userName = config.username;
in
{
  flake.modules = {
    nixos.desktop-niri-standalone =
      { lib, pkgs, ... }:
      let
        system = pkgs.stdenv.hostPlatform.system;
        niriPackage = inputs.niri.packages.${system}.niri-unstable;
      in
      {
        services.greetd.enable = lib.mkDefault true;
        services.greetd.settings.default_session.command =
          lib.mkOverride 100 "${niriPackage}/bin/niri --session";
        services.greetd.settings.default_session.user =
          lib.mkOverride 100 userName;
        systemd.user.services.niri-flake-polkit.enable = lib.mkDefault false;
        xdg.portal.extraPortals = lib.mkDefault [ pkgs.xdg-desktop-portal-gtk ];
      };

    homeManager.desktop-niri-standalone =
      { lib, ... }:
      let
        mutableCopy = import ../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../lib/_helpers.nix;
      in
      {
        xdg.configFile = helpers.portalPathOverrides;

        home.activation.provisionNiriStandaloneCustom = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../config/desktops/niri-standalone/custom.kdl;
            target = "$HOME/.config/niri/custom.kdl";
          }
        );
      };
  };
}
