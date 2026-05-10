{ ... }:
{
  # zram: lower latency than any NVMe (lives in RAM) and zero write wear.
  # With RK3588S + 8 GB, memoryPercent=100 = up to ~8 GB of zstd-compressed swap.
  # Future alternative: NVMe swapfile as secondary overflow if needed.
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
  zramSwap.algorithm = "zstd";

  boot.kernel.sysctl = {
    # Prefer keeping data in RAM; only evict to zram when necessary
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 30;

    # Network — BBR + buffers for Gigabit
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_mtu_probing" = 1;
    "net.ipv4.tcp_max_syn_backlog" = 4096;
    "net.core.netdev_max_backlog" = 4096;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.ip_local_port_range" = "1024 65535";

    "fs.file-max" = 2097152;
  };
}
