{ den, ... }:
{
  den.aspects.niri = den.lib.parametric {
    includes = [
      (den.lib.perHost {
        nixos =
          { lib, ... }:
          {
            options.custom.niri.standaloneSession = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Run Niri as a standalone session (greetd launches niri directly) instead of via DMS.";
            };
          };
      })
      (den.lib.take.exactly (
        { host, ... }:
        {
          nixos =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              trackedUser = import ../../../lib/primary-tracked-user.nix { inherit lib; };
              userName = trackedUser.primaryTrackedUserName host;
              system = pkgs.stdenv.hostPlatform.system;
              niriPackage = host.inputs.niri.packages.${system}.niri-unstable;
              xwaylandSatellitePackage = host.inputs.niri.packages.${system}.xwayland-satellite-unstable;
              niriStandaloneSession = config.custom.niri.standaloneSession;
              sessionPriority = if niriStandaloneSession then 100 else 2000;
              sessionCommand = if niriStandaloneSession then "${niriPackage}/bin/niri --session" else "/run/current-system/sw/bin/true";
              niriPortalConfig = {
                default = [ "gtk" ];
                "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
                "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];
                "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
                "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
              };
            in
            {
              imports = [ host.inputs.niri.nixosModules.niri ];

              config = {
                services.greetd.settings.default_session.command = lib.mkOverride sessionPriority sessionCommand;
                services.greetd.settings.default_session.user = lib.mkOverride sessionPriority userName;

                xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
                xdg.portal.config.niri = niriPortalConfig;

                programs.niri = {
                  enable = true;
                  package = niriPackage;
                };

                environment.systemPackages = [
                  xwaylandSatellitePackage
                ];
              };
            };
        }
      ))
    ];

    provides.to-users.homeManager =
      { lib, ... }:
      let
        mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
        helpers = import ../../../lib/_helpers.nix;
        portalExecPath = helpers.portalExecPath;
      in
      {
        xdg.configFile."systemd/user/xdg-desktop-portal-gnome.service.d/override.conf".text = ''
          [Service]
          Environment=PATH=${portalExecPath}
        '';

        home.activation.provisionNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            source = ../../../config/apps/niri/config.kdl;
            target = "$HOME/.config/niri/config.kdl";
          }
        );
      };
  };
}
