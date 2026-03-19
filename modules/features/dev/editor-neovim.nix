{ ... }:
{
  den.aspects.editor-neovim = {
    nixos =
      { ... }:
      {
        # Fix Neovim server socket permissions: increase systemd user session limits.
        # Without this, LSP servers fail with "Failed to start server: operation not permitted"
        # when creating Unix sockets in /run/user/1000/nvim.*
        security.pam.services.systemd-user = {
          limits = [
            # Increase file descriptor limit (default 1024 is too low for LSP servers)
            { domain = "*"; item = "nofile"; type = "-"; value = "65536"; }
            # Increase process limit (prevents fork failures)
            { domain = "*"; item = "nproc"; type = "-"; value = "4096"; }
          ];
        };
      };

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      let
        nvimRuntimeCleanup = pkgs.writeShellScript "nvim-runtime-cleanup" ''
          set -euo pipefail

          state_dir="$HOME/.local/state/nvim"
          cache_dir="$HOME/.cache/nvim"
          swap_dir="$state_dir/swap"
          max_log_size=$((10 * 1024 * 1024)) # 10 MiB

          mkdir -p "$state_dir" "$cache_dir" "$swap_dir"

          trim_log_if_needed() {
            local file="$1"
            [ -f "$file" ] || return 0
            local size
            size="$(${pkgs.coreutils}/bin/stat -c %s "$file" 2>/dev/null || echo 0)"
            if [ "$size" -gt "$max_log_size" ]; then
              ${pkgs.coreutils}/bin/tail -n 5000 "$file" > "$file.tmp"
              ${pkgs.coreutils}/bin/mv "$file.tmp" "$file"
            fi
          }

          trim_log_if_needed "$state_dir/lsp.log"
          trim_log_if_needed "$cache_dir/dap.log"

          if [ -d "$swap_dir" ]; then
            ${pkgs.findutils}/bin/find "$swap_dir" -type f \
              \( -name "*.swp" -o -name "*.swo" -o -name "*.swn" -o -name "*.tmp" \) \
              -mtime +14 -delete
          fi
        '';
      in
      {
        programs.neovim = {
          enable = true;
          defaultEditor = true;
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
          withPython3 = true;
        };

        home.activation.syncNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -p "$HOME/.config/nvim"
          $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete ${../../../config/apps/nvim}/ "$HOME/.config/nvim/"
          $DRY_RUN_CMD chmod -R u+rwX,go+rX "$HOME/.config/nvim"
        '';

        home.packages = with pkgs; [
          # Python
          pyright
          ruff
          python3Packages.debugpy

          # Lua / Nix / TOML
          lua-language-server
          stylua
          nil
          taplo

          # JS/TS/JSON/Bash language servers
          vtsls
          vscode-js-debug
          nodePackages.typescript
          nodePackages.vscode-langservers-extracted
          nodePackages.bash-language-server

          # Rust
          rust-analyzer
          lldb

          # Go
          go
          gopls
          gotools
          gofumpt

          # Common format/lint helpers
          marksman
          shfmt
        ];

        systemd.user.services.nvim-runtime-cleanup = {
          Unit.Description = "Neovim runtime cleanup (safe allowlist)";
          Service = {
            Type = "oneshot";
            ExecStart = nvimRuntimeCleanup;
          };
        };

        systemd.user.timers.nvim-runtime-cleanup = {
          Unit.Description = "Weekly Neovim runtime cleanup";
          Timer = {
            OnBootSec = "20min";
            OnCalendar = "weekly";
            Persistent = true;
            Unit = "nvim-runtime-cleanup.service";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
  };
}
