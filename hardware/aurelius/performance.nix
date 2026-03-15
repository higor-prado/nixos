{ ... }:
{
  zramSwap.enable = true;
  zramSwap.memoryPercent = 100;
  zramSwap.algorithm = "zstd";

  boot.kernel.sysctl = {
    # Memory: conservative swappiness for server workloads
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;

    # Network throughput — raise buffer ceilings and use BBR
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.core.somaxconn" = 8192;

    # File descriptor headroom
    "fs.file-max" = 2097152;
  };
}
