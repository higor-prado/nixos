{ config, pkgs, ... }:

{
  zramSwap.enable = true;
  zramSwap.memoryPercent = 50;
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
    "vm.swappiness" = 100; # Balanced for high-RAM desktop with ZRAM (180 is for low-RAM)
    "vm.vfs_cache_pressure" = 40;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    # Compaction proactiveness (reduces latency from memory fragmentation)
    "vm.compaction_proactiveness" = 20;
    # Transparent hugepages — better for dev workloads
    "vm.page-cluster" = 0; # Don't read-ahead swap pages (ZRAM is random-access)
    # Proton/Wine requires ≥524288; VSCode, Electron, JVM apps also benefit
    "vm.max_map_count" = 2097152;
    # Suppress kswapd boost after reclaim (unnecessary overhead with ZRAM)
    "vm.watermark_boost_factor" = 0;
    # Reserve 512 MB so the kernel can always run OOM killer and handle interrupts
    "vm.min_free_kbytes" = 524288;
    # Kill the task that triggered the OOM condition, not a random victim
    "vm.oom_kill_allocating_task" = 1;
    # Widen low/high watermark gap slightly — reduces kswapd wakeups under transient pressure.
    # 50 (0.5% of memory) balances early reclaim with unnecessary compression on 32GB RAM.
    # min_free_kbytes=524288 already reserves 512MB as emergency; wide watermarks are redundant above 50.
    "vm.watermark_scale_factor" = 50;

    # ── Scheduler ──
    "kernel.sched_autogroup_enabled" = 1;
    # NMI watchdog generates periodic interrupts causing latency spikes; irrelevant on desktop
    "kernel.nmi_watchdog" = 0;

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
    # Larger backlog + budget — prevents NIC rx drops under broadcast bursts
    "net.core.netdev_max_backlog" = 4096;
    "net.core.netdev_budget" = 2048;
    "net.core.rps_sock_flow_entries" = 32768;

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

    # Keep nice/ionice/oom tuning, but do not let rules set Linux scheduler class.
    # With CachyOS rules, BG_CPUIO carries sched=idle (e.g. greetd), and that
    # can leak SCHED_IDLE to the graphical session tree, hurting responsiveness under load.
    settings.apply_sched = false;

    # Override sensitive login/session bootstrap processes so they never inherit
    # BG_CPUIO defaults from upstream rules.
    extraRules = [
      {
        name = "greetd";
        type = "Service";
      }
      {
        name = "start-hyprland";
        type = "LowLatency_RT";
      }
      {
        name = "keyrs";
        type = "LowLatency_RT";
      }
    ];
  };

  # Ensure ananicy daemon is restarted whenever its generated /etc payload changes.
  # Without restart, stale runtime policy can survive switches.
  systemd.services.ananicy-cpp.restartTriggers = [
    config.environment.etc."ananicy.d".source
  ];

  # ══════════════════════════════════════════════
  # CPU Frequency Scaling
  # ══════════════════════════════════════════════
  # intel_pstate with performance governor reduces ramp latency for burst
  # workloads (compilation, dev tools). HWP still drops frequency at idle.
  boot.kernelParams = [
    "intel_pstate=active"
    "transparent_hugepage=madvise"
  ];
  powerManagement.cpuFreqGovernor = "performance";

  # RPS — distribute NIC rx processing across all CPUs.
  # udev ATTR races with kernel creating queues/rx-0/rps_cpus → use oneshot.
  systemd.services.set-rps = {
    description = "Enable RPS on Ethernet interfaces";
    after = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    path = with pkgs; [ coreutils ];
    script = ''
      for attempt in $(seq 1 50); do
        rps=/sys/class/net/enp111s0/queues/rx-0/rps_cpus
        if [ -f "$rps" ] && [ -w "$rps" ]; then
          echo fffff > "$rps" && exit 0
        fi
        sleep 0.1
      done
      echo "RPS: enp111s0 rps_cpus not ready after 5s" >&2
    '';
  };

  # Note: power-profiles-daemon is disabled in system.nix
  # Note: thermald is disabled in system.nix (conflicts with linuwu-sense)
}
