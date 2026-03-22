{ ... }:
{
  flake.modules.nixos.maintenance =
    { pkgs, ... }:
    {
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };

      systemd.services.disk-usage-alert = {
        description = "Log disk usage alert if root filesystem exceeds 80%";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "disk-usage-alert" ''
            set -euo pipefail
            usage=$(${pkgs.coreutils}/bin/df / --output=pcent | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.gnused}/bin/sed 's/[^0-9]//g')
            if [ "$usage" -gt 80 ]; then
              echo "DISK USAGE ALERT: root filesystem at ''${usage}%"
            else
              echo "Disk usage OK: root filesystem at ''${usage}%"
            fi
          '';
        };
      };

      systemd.timers.disk-usage-alert = {
        description = "Daily disk usage check";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

    };
}
