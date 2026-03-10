{ ... }:

{
  disko.devices = {
    disk.system = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-Micron_3400_MTFDKBA1T0TFH_23364390AD22";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
disk.home = {
      type = "disk";
      device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_2000GB_24023B803493";
      content = {
        type = "gpt";
        partitions = {

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypthome";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {

                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd:3"
                      "noatime"
                    ];
                  };

                };
              };
            };
          };

        };
      };
    };

  };

}
