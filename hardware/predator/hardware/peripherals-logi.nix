{ pkgs, ... }:
{
  environment.etc."logid.cfg".text = builtins.readFile ../../../config/apps/logid/logid.cfg;
  services.dbus.packages = [ pkgs.logiops ];

  systemd.services.logid = {
    description = "LogiOps (logid) for Logitech HID++ devices";
    wantedBy = [ "multi-user.target" ];
    after = [
      "dbus.service"
      "bluetooth.service"
    ];
    wants = [
      "dbus.service"
      "bluetooth.service"
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  systemd.services."logid-restart@" = {
    description = "Restart logid when Logitech device appears (%I)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --no-block restart logid.service";
    };
  };

  services.udev.extraRules = ''
    # LogiOps - uaccess for Logitech devices
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="uaccess"

    # LogiOps - restart logid when Logitech device appears
    ACTION=="add|change", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", TAG+="systemd", ENV{SYSTEMD_WANTS}+="logid-restart@%k.service"
  '';
}
