{ inputs, ... }:
{
  flake.modules.homeManager.waybar =
    { pkgs, lib, ... }:
    let
      mutableCopy = import ../../../lib/mutable-copy.nix { inherit lib; };
      provisionCopyOnce =
        {
          name,
          source,
          mode ? "0644",
        }:
        lib.hm.dag.entryAfter [ "writeBoundary" ] (
          mutableCopy.mkCopyOnce {
            inherit source mode;
            target = "$HOME/.config/waybar/" + name;
          }
        );
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        package = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar;
      };

      catppuccin.waybar.mode = "createLink";

      systemd.user.services.waybar = {
        Unit.ConditionEnvironment = "WAYLAND_DISPLAY";
        Service = {
          RestartSec = "2";
          LimitCORE = "0";
        };
      };

      home.activation = {
        provisionWaybarConfig = provisionCopyOnce {
          name = "config";
          source = ../../../config/apps/waybar/config;
        };
        provisionWaybarStyle = provisionCopyOnce {
          name = "style.css";
          source = ../../../config/apps/waybar/style.css;
        };
        provisionWaybarMakoScript = provisionCopyOnce {
          name = "scripts/mako.sh";
          source = ../../../config/apps/waybar/scripts/mako.sh;
          mode = "0755";
        };
        provisionWaybarMakoDndScript = provisionCopyOnce {
          name = "scripts/mako-dnd.sh";
          source = ../../../config/apps/waybar/scripts/mako-dnd.sh;
          mode = "0755";
        };
        provisionWaybarMakoClearScript = provisionCopyOnce {
          name = "scripts/mako-clear.sh";
          source = ../../../config/apps/waybar/scripts/mako-clear.sh;
          mode = "0755";
        };
        provisionWaybarActiveWindowScript = provisionCopyOnce {
          name = "scripts/active-window.sh";
          source = ../../../config/apps/waybar/scripts/active-window.sh;
          mode = "0755";
        };
        provisionWaybarBottomConfig = provisionCopyOnce {
          name = "bottom";
          source = ../../../config/apps/waybar/bottom;
        };
      };

      systemd.user.services.waybar-bottom = {
        Unit = {
          Description = "Waybar bottom bar";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          After = [ "graphical-session.target" ];
          PartOf = [
            "tray.target"
            "graphical-session.target"
          ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${
            lib.getExe inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.waybar
          } -c %h/.config/waybar/bottom";
          Restart = "on-failure";
          RestartSec = "2";
          KillMode = "mixed";
          LimitCORE = "0";
        };
        Install.WantedBy = [
          "tray.target"
          "graphical-session.target"
        ];
      };

    };
}
