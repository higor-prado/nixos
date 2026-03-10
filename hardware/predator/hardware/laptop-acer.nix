{ config, pkgs, ... }:
let
  linuwu-sense = config.boot.kernelPackages.callPackage ../../../pkgs/linuwu-sense.nix { };

  setPlatformProfileScript = pkgs.writeShellScript "set-platform-profile" ''
    set -euo pipefail

    PROFILE_FILE="/sys/firmware/acpi/platform_profile"
    CHOICES_FILE="/sys/firmware/acpi/platform_profile_choices"

    for i in $(seq 1 50); do
      if [ -w "$PROFILE_FILE" ]; then
        break
      fi
      sleep 0.1
    done

    if [ ! -w "$PROFILE_FILE" ]; then
      echo "platform_profile: file not available/writable: $PROFILE_FILE" >&2
      exit 0
    fi

    choices=""
    if [ -r "$CHOICES_FILE" ]; then
      choices="$(cat "$CHOICES_FILE" || true)"
    fi

    pick_and_set() {
      local target="$1"
      if [ -n "$choices" ]; then
        echo "$choices" | tr ' ' '\n' | grep -qx "$target" || return 1
      fi
      echo "$target" > "$PROFILE_FILE"
      echo "platform_profile set to: $target"
      return 0
    }

    pick_and_set "balanced-performance" || \
    pick_and_set "performance" || \
    pick_and_set "balanced" || \
    (echo "platform_profile: no expected profile found. choices='$choices'" >&2; exit 0)
  '';
in
{
  # Kernel packages (latest for GPU/hardware compatibility)
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Note: acer-wmi is blacklisted - replaced by linuwu-sense
  boot.extraModulePackages = [ linuwu-sense ];
  boot.blacklistedKernelModules = [
    "acer_wmi" # Replaced by linuwu_sense
    "processor_thermal_device_pci" # Conflicts with Acer thermal management
  ];

  users.groups.linuwu_sense = { };

  systemd.tmpfiles.rules = [
    "f /sys/firmware/acpi/platform_profile 0664 root wheel - -"
    "z /sys/devices/platform/acer-wmi 0775 root wheel - -"
    "Z /sys/devices/platform/acer-wmi - root wheel - -"
  ];

  systemd.services.set-platform-profile = {
    description = "Set ACPI platform_profile (balanced-performance)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "systemd-modules-load.service"
      "sysinit.target"
    ];
    wants = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = setPlatformProfileScript;
    };
  };

  environment.etc."systemd/system-sleep/set-platform-profile" = {
    mode = "0755";
    source = pkgs.writeShellScript "set-platform-profile-sleep-hook" ''
      [ "$1" = "post" ] || exit 0
      exec ${setPlatformProfileScript}
    '';
  };

  # IMPORTANT: thermald is DISABLED for Acer Predator
  # Intel thermal device is blacklisted; thermal management is via linuwu_sense
  services.thermald.enable = false;

  # Disable power-profiles-daemon (conflicts with platform_profile)
  services.power-profiles-daemon.enable = false;

  # Firmware update service
  services.fwupd.enable = true;

  services.udev.extraRules = ''
    # Acer WMI - permissions for linuwu-sense
    ACTION=="add", SUBSYSTEM=="platform", DRIVER=="acer-wmi", RUN+="${pkgs.coreutils}/bin/chmod -R g+w /sys/devices/platform/acer-wmi/"
    ACTION=="add", SUBSYSTEM=="platform", DRIVER=="acer-wmi", RUN+="${pkgs.coreutils}/bin/chgrp -R wheel /sys/devices/platform/acer-wmi/"
  '';
}
