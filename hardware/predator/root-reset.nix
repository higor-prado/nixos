{ pkgs, ... }:
let
  cryptroot = "/dev/mapper/cryptroot";
  topLevelMount = "/btrfs_tmp";
  rootSubvolume = "@root";
  archivedRoots = "@old-roots";
  retentionDays = 30;
in
{
  # The upstream impermanence README shows Btrfs root reset via
  # `boot.initrd.postResumeCommands`, but predator uses
  # `boot.initrd.systemd.enable = true`, and NixOS rejects that hook in
  # systemd stage-1. This host therefore has to express the same logic as an
  # initrd systemd unit instead.
  #
  # The correct stage-1 pattern for extra binaries is
  # `boot.initrd.systemd.initrdBin`. The first unit version used `path = [ ... ]`
  # and then absolute store paths, but the boot journal still showed
  # `mount: command not found` / missing initrd store paths. Keep the service
  # script normal and put its tool dependencies into the initrd bin path.
  boot.initrd.systemd.initrdBin = [
    pkgs.btrfs-progs
    pkgs.coreutils
    pkgs.findutils
    pkgs.util-linux
  ];

  boot.initrd.systemd.services.root-reset = {
    description = "Reset Btrfs root subvolume before mounting sysroot";
    wantedBy = [ "initrd.target" ];
    before = [
      "sysroot.mount"
      "initrd-root-fs.target"
    ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    requires = [ "systemd-cryptsetup@cryptroot.service" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p ${topLevelMount}
      mount -t btrfs -o subvolid=5 ${cryptroot} ${topLevelMount}

      delete_subvolume_recursively() {
        IFS=$'\n'
        for child in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "${topLevelMount}/$child"
        done
        btrfs subvolume delete "$1"
      }

      mkdir -p ${topLevelMount}/${archivedRoots}

      if [[ -e ${topLevelMount}/${rootSubvolume} ]]; then
        timestamp=$(date --date="@$(stat -c %Y ${topLevelMount}/${rootSubvolume})" "+%Y-%m-%d_%H:%M:%S")
        mv ${topLevelMount}/${rootSubvolume} "${topLevelMount}/${archivedRoots}/$timestamp"
      fi

      if [[ -d ${topLevelMount}/${archivedRoots} ]]; then
        for old_root in $(find ${topLevelMount}/${archivedRoots} -maxdepth 1 -mindepth 1 -mtime +${toString retentionDays}); do
          delete_subvolume_recursively "$old_root"
        done
      fi

      btrfs subvolume create ${topLevelMount}/${rootSubvolume}
      mkdir -p \
        ${topLevelMount}/${rootSubvolume}/boot \
        ${topLevelMount}/${rootSubvolume}/etc \
        ${topLevelMount}/${rootSubvolume}/home \
        ${topLevelMount}/${rootSubvolume}/nix \
        ${topLevelMount}/${rootSubvolume}/persist \
        ${topLevelMount}/${rootSubvolume}/root \
        ${topLevelMount}/${rootSubvolume}/swap \
        ${topLevelMount}/${rootSubvolume}/tmp \
        ${topLevelMount}/${rootSubvolume}/var/log

      umount ${topLevelMount}
      rmdir ${topLevelMount}
    '';
  };
}
