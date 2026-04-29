{ ... }:
{
  flake.modules.homeManager.vicinae =
    { pkgs, ... }:
    let
      vicinaeToggle = pkgs.writeShellApplication {
        name = "vicinae-toggle";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.systemd
          pkgs.vicinae
        ];
        text = ''
          if ! vicinae ping >/dev/null 2>&1; then
            systemctl --user start vicinae.service
            for _ in $(seq 1 50); do
              if vicinae ping >/dev/null 2>&1; then
                break
              fi
              sleep 0.1
            done
          fi

          exec vicinae toggle
        '';
      };
    in
    {
      # Keep Rofi as the primary launcher until Vicinae is accepted, but run the
      # daemon in the graphical session so `vicinae toggle` has a socket to talk to.
      home.packages = [
        pkgs.vicinae
        vicinaeToggle
      ];

      systemd.user.services.vicinae = {
        Unit = {
          Description = "Vicinae launcher daemon";
          Documentation = [ "https://docs.vicinae.com" ];
          Requires = [ "dbus.socket" ];
          After = [ "hyprland-session.target" ];
          PartOf = [ "hyprland-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.vicinae}/bin/vicinae server --replace";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          Restart = "on-failure";
          RestartSec = 5;
          KillMode = "process";
        };
        Install.WantedBy = [ "hyprland-session.target" ];
      };
    };
}
