{ inputs, ... }:
{
  flake.modules.homeManager.dms-wallpaper =
    { lib, pkgs, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
      customPkgs = import ../../../pkgs { inherit pkgs inputs; };
      dmsPackage = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell;
      dmsAwwwConfigTemplate = builtins.readFile ../../../config/apps/dms/dms-awww-config.toml.in;
      runDmsAwww = pkgs.writeShellApplication {
        name = "run-dms-awww";
        runtimeInputs = [
          pkgs.awww
          pkgs.matugen
        ];
        text = ''
          export DMS_AWWW_BIN=${lib.escapeShellArg "${customPkgs.dms-awww}/bin/dms-awww"}
          ${builtins.readFile ../../../config/apps/dms/run-dms-awww.sh}
        '';
      };
    in
    {
      home.packages = [
        pkgs.awww
        customPkgs.dms-awww
      ];
      home.activation.provisionDmsSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        mutableCopy.mkCopyOnce {
          source = ../../../config/apps/dms/settings.json;
          target = "$HOME/.config/DankMaterialShell/settings.json";
        }
      );
      xdg.configFile."dms-awww/config.toml".text = ''
        ${lib.replaceStrings
          [ "@DMS_SHELL_DIR@" ]
          [ "${dmsPackage}/share/quickshell/dms" ]
          dmsAwwwConfigTemplate}
      '';
      systemd.user.services = {
        awww-daemon = {
          Unit = {
            Description = "swww wallpaper daemon (awww-daemon)";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
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
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
        dms-awww = {
          Unit = {
            Description = "DMS-AWWW: wallpaper + matugen integration for DMS";
            Documentation = [ "https://github.com/higorprado/dms-awww-integration" ];
            After = [
              "graphical-session.target"
              "awww-daemon.service"
            ];
            PartOf = [ "graphical-session.target" ];
            Requires = [ "awww-daemon.service" ];
            ConditionPathExists = [ "%h/.config/dms-awww/config.toml" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${runDmsAwww}/bin/run-dms-awww";
            Restart = "on-failure";
            RestartSec = 5;
            Environment = [
              "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
              "HOME=%h"
              "XDG_RUNTIME_DIR=/run/user/%U"
            ];
            EnvironmentFile = "-%h/.config/dms-awww/environment";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            ReadWritePaths = [
              "/tmp"
              "%h/.config/DankMaterialShell"
              "%h/.cache/DankMaterialShell"
              "/run/user/%U"
            ];
            StandardOutput = "journal";
            StandardError = "journal";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
