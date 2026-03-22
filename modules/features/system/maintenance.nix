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

      systemd.services.flake-update-check = {
        description = "Report how long ago flake inputs were last updated";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "flake-update-check" ''
            set -euo pipefail
            lockfile=/etc/nixos/flake.lock
            if [ ! -f "$lockfile" ]; then
              echo "flake.lock not found at $lockfile"
              exit 0
            fi
            mtime=$(${pkgs.coreutils}/bin/stat -c %Y "$lockfile")
            now=$(${pkgs.coreutils}/bin/date +%s)
            age_days=$(( (now - mtime) / 86400 ))
            echo "flake.lock last modified ''${age_days} days ago"
            if [ "$age_days" -ge 7 ]; then
              echo "FLAKE UPDATE REMINDER: inputs are ''${age_days} days old — consider running nix flake update"
            fi
          '';
        };
      };

      systemd.timers.flake-update-check = {
        description = "Weekly reminder to update flake inputs";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
        };
      };
    };
}
