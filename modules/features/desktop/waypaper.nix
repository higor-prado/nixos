{ inputs, ... }:
{
  flake.modules.homeManager.waypaper =
    { lib, pkgs, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
      waypaper = pkgs.waypaper.overrideAttrs (_old: {
        version = "2.8";
        src = inputs.waypaper-src;
      });
    in
    {
      home.packages = [
        waypaper
        pkgs.awww
      ];

      home.activation.provisionWaypaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/waypaper/config.ini;
          target = "$HOME/.config/waypaper/config.ini";
        }
      );

      systemd.user.services.awww-daemon = {
        Unit = {
          Description = "swww wallpaper daemon (awww-daemon)";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
          StartLimitBurst = 5;
          StartLimitIntervalSec = 60;
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.awww}/bin/awww-daemon";
          Environment = [
            "HOME=%h"
            "XDG_RUNTIME_DIR=/run/user/%U"
          ];
          Restart = "on-failure";
          RestartSec = 2;
          StandardOutput = "journal";
          StandardError = "journal";
          LimitCORE = "0";
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
