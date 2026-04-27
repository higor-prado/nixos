{ ... }:
{
  flake.modules.nixos.keyrs =
    { lib, ... }:
    {
      hardware.uinput.enable = true;
      services.keyrs.enable = true;

      # keyrs is display-session-bound on this desktop. The upstream unit is
      # wanted by default.target and wants graphical-session.target, which makes
      # SSH/linger user-manager startup pull the full graphical session before a
      # Wayland compositor exists.
      systemd.user.services.keyrs = {
        wantedBy = lib.mkForce [ "graphical-session.target" ];
        wants = lib.mkForce [ ];
        after = lib.mkForce [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
      };
    };
}
