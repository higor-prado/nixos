{ pkgs, ... }:

{
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
  zramSwap.algorithm = "zstd";

  # ══════════════════════════════════════════════
  # OOM Protection
  # ══════════════════════════════════════════════
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # ══════════════════════════════════════════════
  # Sysctl Tuning
  # ══════════════════════════════════════════════
  # CachyOS uses: bpftune (auto-tuning) + ananicy-cpp (process niceness)
  # NixOS equivalent: explicit sysctl + ananicy-cpp
  boot.kernel.sysctl = {
    # ── Memory management ──
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    # Compaction proactiveness (reduces latency from memory fragmentation)
    "vm.compaction_proactiveness" = 20;
    # Transparent hugepages — better for dev/gaming workloads
    "vm.page-cluster" = 0; # Don't read-ahead swap pages (ZRAM is random-access)

    # ── Scheduler ──
    "kernel.sched_autogroup_enabled" = 1;

    # ── Network performance ──
    # BBR congestion control (better than CachyOS default cubic)
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3; # Enable TCP Fast Open (client + server)
    # Don't re-throttle throughput after idle (helps Tailscale, SSH, HTTP keep-alives)
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    # PMTUD probing — avoids MTU blackholes on WiFi and upstream routers
    "net.ipv4.tcp_mtu_probing" = 1;

    # ── inotify limits (critical for dev tools) ──
    # neovim, vscode, webpack, vite, etc. all need high limits
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;

    # ── File descriptor limits ──
    "fs.file-max" = 2097152;
  };

  # ══════════════════════════════════════════════
  # Ananicy-cpp: Process Priority Daemon
  # ══════════════════════════════════════════════
  # CachyOS runs ananicy-cpp to auto-nice processes (compilers low, desktop high).
  # This significantly improves desktop responsiveness during heavy compilation.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraRules = [
      {
        name = "keyrs";
        type = "LowLatency_RT";
      }
    ];
  };

  # ══════════════════════════════════════════════
  # SSD Health Monitoring
  # ══════════════════════════════════════════════
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  # ══════════════════════════════════════════════
  # CPU Frequency Scaling
  # ══════════════════════════════════════════════
  # CachyOS uses intel_pstate with powersave governor (HWP handles boost).
  # NixOS default is ondemand via acpi-cpufreq. Force intel_pstate to match.
  boot.kernelParams = [ "intel_pstate=active" ];
  powerManagement.cpuFreqGovernor = "powersave"; # intel_pstate HWP handles boost

  # ══════════════════════════════════════════════
  # Nix Daemon Scheduling
  # ══════════════════════════════════════════════
  # Run nix-daemon at idle CPU/IO priority so builds never preempt desktop processes.
  # Stronger guarantee than ananicy-cpp niceness alone (uses systemd cgroup scheduling).
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  # Note: power-profiles-daemon is disabled in system.nix
  # Note: thermald is disabled in system.nix (conflicts with linuwu-sense)
}
