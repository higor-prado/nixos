{ ... }:
{
  flake.modules.nixos.editors-neovim =
    { ... }:
    {
      # Fix Neovim server socket permissions: increase systemd user session limits.
      # Without this, LSP servers fail with "Failed to start server: operation not permitted"
      # when creating Unix sockets in /run/user/1000/nvim.*
      security.pam.services.systemd-user = {
        limits = [
          # Increase file descriptor limit (default 1024 is too low for LSP servers)
          {
            domain = "*";
            item = "nofile";
            type = "-";
            value = "65536";
          }
          # Increase process limit (prevents fork failures)
          {
            domain = "*";
            item = "nproc";
            type = "-";
            value = "4096";
          }
        ];
      };
    };

  flake.modules.homeManager.editors-neovim =
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

      nvimStaleProcessCleanup = pkgs.writeShellScript "nvim-stale-process-cleanup" ''
        set -euo pipefail

        ${pkgs.python3}/bin/python3 - <<'PY'
        import os
        import signal
        import time

        def read_text(path):
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as f:
                    return f.read()
            except OSError:
                return ""

        def cmdline(pid):
            try:
                return open(f"/proc/{pid}/cmdline", "rb").read().replace(b"\0", b" ").decode("utf-8", "replace").strip()
            except OSError:
                return ""

        def comm(pid):
            return read_text(f"/proc/{pid}/comm").strip()

        def ppid(pid):
            try:
                return int(read_text(f"/proc/{pid}/stat").split()[3])
            except (OSError, IndexError, ValueError):
                return 0

        def has_deleted_tty(pid):
            for fd in ("0", "1", "2"):
                try:
                    target = os.readlink(f"/proc/{pid}/fd/{fd}")
                except OSError:
                    continue
                if target.startswith("/dev/pts/") and target.endswith(" (deleted)"):
                    return True
            return False

        def user_systemd(pid):
            return comm(pid) == "systemd" and " --user " in f" {cmdline(pid)} "

        def environ(pid):
            try:
                return open(f"/proc/{pid}/environ", "rb").read().split(b"\0")
            except OSError:
                return []

        def from_kitty_graphical_scope(pid):
            cgroup = read_text(f"/proc/{pid}/cgroup")
            if "/app-graphical.slice/kitty-" not in cgroup:
                return False

            env = environ(pid)
            return any(item.startswith(b"KITTY_PID=") for item in env) and any(
                item.startswith(b"KITTY_WINDOW_ID=") for item in env
            )

        processes = []
        children = {}
        for name in os.listdir("/proc"):
            if not name.isdigit():
                continue
            pid = int(name)
            parent = ppid(pid)
            processes.append(pid)
            children.setdefault(parent, []).append(pid)

        def descendants(pid):
            pending = list(children.get(pid, []))
            result = []
            while pending:
                child = pending.pop()
                result.append(child)
                pending.extend(children.get(child, []))
            return result

        stale_roots = []
        for pid in processes:
            command = cmdline(pid)
            if comm(pid) != "nvim":
                continue
            if " --embed" not in f" {command} ":
                continue
            if not from_kitty_graphical_scope(pid):
                continue
            if not has_deleted_tty(pid):
                continue
            if not user_systemd(ppid(pid)):
                continue
            stale_roots.append(pid)

        targets = []
        for root in stale_roots:
            targets.extend(descendants(root))
            targets.append(root)

        for sig in (signal.SIGTERM, signal.SIGKILL):
            for pid in targets:
                try:
                    os.kill(pid, sig)
                except ProcessLookupError:
                    pass
                except PermissionError:
                    pass
            if sig == signal.SIGTERM:
                time.sleep(2)
        PY
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
        withRuby = false;
      };

      home.activation.syncNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -p "$HOME/.config/nvim"
        $DRY_RUN_CMD ${pkgs.rsync}/bin/rsync -a --delete ${../../../config/apps/nvim}/ "$HOME/.config/nvim/"
        $DRY_RUN_CMD chmod -R u+rwX,go+rX "$HOME/.config/nvim"
      '';

      home.packages = with pkgs; [
        pyright
        ruff
        python3Packages.debugpy
        lua-language-server
        stylua
        nil
        taplo
        vtsls
        vscode-js-debug
        typescript
        vscode-langservers-extracted
        bash-language-server
        rust-analyzer
        lldb
        go
        gopls
        gofumpt
        markdown-oxide
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

      systemd.user.services.nvim-stale-process-cleanup = {
        Unit.Description = "Neovim stale embedded process cleanup";
        Service = {
          Type = "oneshot";
          ExecStart = nvimStaleProcessCleanup;
        };
      };

      systemd.user.timers.nvim-stale-process-cleanup = {
        Unit.Description = "Periodic Neovim stale embedded process cleanup";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "2min";
          Unit = "nvim-stale-process-cleanup.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
