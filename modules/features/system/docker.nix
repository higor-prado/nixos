{ ... }:
{
  flake.modules = {
    nixos.docker =
      { pkgs, ... }:
      {
        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune = {
            enable = true;
            dates = "weekly";
          };
        };

        systemd.services.docker-health-check = {
          description = "Log unhealthy Docker containers";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "docker-health-check" ''
              set -euo pipefail
              unhealthy=$(${pkgs.docker}/bin/docker ps --filter health=unhealthy --format '{{.Names}} {{.Status}}' 2>/dev/null)
              if [ -n "$unhealthy" ]; then
                echo "UNHEALTHY CONTAINERS:"
                echo "$unhealthy"
              else
                echo "All containers healthy."
              fi
            '';
          };
        };

        systemd.timers.docker-health-check = {
          description = "Periodically check Docker container health";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*:0/15";
            Persistent = true;
          };
        };
      };

    homeManager.docker =
      { ... }:
      {
        programs.fish.shellAbbrs = {
          dps = "docker ps";
          dpsa = "docker ps -a";
          di = "docker images";
          dex = "docker exec -it";
        };
      };
  };
}
