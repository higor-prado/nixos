{ ... }:
{
  den.aspects.backup-service = {
    homeManager =
      { pkgs, ... }:
      let
        backupScript = pkgs.writeShellScriptBin "backup-critical" ''
          #!/usr/bin/env bash
          set -euo pipefail

          BACKUP_ROOT="$HOME/Backups/nixos-critical"
          DATE="$(date +%Y%m%d-%H%M%S)"
          BACKUP_DIR="$BACKUP_ROOT/$DATE"

          mkdir -p "$BACKUP_DIR"

          echo "Backing up critical non-declarative items to $BACKUP_DIR"

          if [ -d "$HOME/.ssh" ]; then
            echo "Backing up SSH keys..."
            tar -czf "$BACKUP_DIR/ssh.tar.gz" \
              -C "$HOME" \
              --ignore-failed-read \
              .ssh/id_ed25519 .ssh/id_ed25519.pub \
              .ssh/id_rsa .ssh/id_rsa.pub \
              .ssh/config 2>/dev/null || true
          fi

          if [ -d "$HOME/.gnupg" ] && [ "$(ls -A $HOME/.gnupg 2>/dev/null)" ]; then
            echo "Backing up GPG keys..."
            tar -czf "$BACKUP_DIR/gnupg.tar.gz" -C "$HOME" .gnupg
          fi

          if ${pkgs.glib}/bin/gsettings list-keys org.gnome.desktop.interface &>/dev/null; then
            echo "Backing up dconf settings..."
            ${pkgs.glib}/bin/dconf dump / > "$BACKUP_DIR/dconf-full.ini" 2>/dev/null || echo "  No dconf settings"
          fi

          echo "Creating manifest..."
          cat > "$BACKUP_DIR/manifest.txt" << EOF
          Backup created: $(date)
          Hostname: $(hostname)
          Username: $(whoami)
          Files included:
          $(ls -la "$BACKUP_DIR" | grep -v manifest)
          EOF

          echo "Cleaning old backups (keeping last 10)..."
          ls -t "$BACKUP_ROOT" | tail -n +11 | while read old; do
            rm -rf "$BACKUP_ROOT/$old"
            echo "  Removed: $old"
          done

          echo "Backup complete: $BACKUP_DIR"
        '';
      in
      {
        systemd.user.services.critical-backup = {
          Unit.Description = "Daily backup of critical non-declarative data";
          Service = {
            Type = "oneshot";
            ExecStart = "${backupScript}/bin/backup-critical";
          };
        };
        systemd.user.timers.critical-backup = {
          Unit.Description = "Timer for critical data backup (daily)";
          Timer = {
            OnCalendar = "daily";
            Persistent = true;
            Unit = "critical-backup.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
  };
}
