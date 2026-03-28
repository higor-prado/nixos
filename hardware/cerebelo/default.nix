{ lib, ... }:
let
  storage = import ./storage-identifiers.nix;
in
{
  imports = [
    ./board.nix
    ./hardware-configuration.nix
    ./performance.nix
  ] ++ lib.optional (builtins.pathExists ../../private/hosts/cerebelo/default.nix)
       ../../private/hosts/cerebelo/default.nix;

  # O stack oficial do Orange Pi 5 acrescenta a parte RK3588/vendor;
  # aqui só sobrescrevemos o root UUID para o NVMe já provisionado.
  boot.kernelParams = lib.mkForce [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
    "root=UUID=${storage.nvmeRootUuid}"
    "rootfstype=ext4"
    "rootwait"
    "earlycon"
    "consoleblank=0"
    "console=ttyS2,1500000"
    "console=tty1"
    "cgroup_enable=cpuset"
    "cgroup_memory=1"
    "cgroup_enable=memory"
    "swapaccount=1"
  ];
  boot.consoleLogLevel = 7;

}
